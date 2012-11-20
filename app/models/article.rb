class Article < ActiveRecord::Base
  
  # Model definition
  ############################################################################

  # Export handlers
  braincube_set_export_columns(
    ["ID",              :id],
    ["Title",           :title],
    ["Abstract",        :abstract],
    ["Standfirst",      :standfirst],
    ["Content",         :content],
    ["Authors",         :cached_authors],
    ["Tags",            :cached_tags],
    ["Article type",    :article_type],
    ["Live time",       :starts_at],
    ["End time",        :ends_at],
    ["Review",          :review],
    ["Review rating",   :review_rating],
    ["Print only",      :print_only],
    ["Status",          :status],
    ["Web address",     :web_address],
    ["Properties",      :properties]
  )
  
  # Constants 
  Status = {
    :unsubmitted => "NEW", 
    :editing     => "EDITING",
    :subediting  => "SUBEDITING", 
    :ready       => "READY", 
    :published   => "PUBLISHED", 
    :removed     => "REMOVED" 
  }
  
  SortOrder = {
    :rating => "review_rating DESC",
    :name   => "articles.title ASC",
    :newest => "starts_at DESC, articles.created_at DESC"
  }
  
  
  # Relationships
  belongs_to :section
  belongs_to :publication
  belongs_to :user
  has_and_belongs_to_many :events
  has_and_belongs_to_many :venues
  has_many :reviewed_events, :class_name => "Event", :foreign_key => "review_id", :dependent => :nullify
  has_many :performances, :through => :events
  
  
  # Authors
  has_many :authors, :order => :sort_order, :dependent => :destroy
  has_many :authoring_users, :through => :authors, :source => :user,
           :class_name => "User", :foreign_key => "user_id"
  after_save :build_authors
  attr_accessor :writer_string
  def writer_string
    cached_authors
  end
  
  # Event and venue attachment
  attr_accessor :associated_event_ids
  attr_accessor :associated_venue_ids
  before_save :associate_events_and_venues

  # Library stuff
  braincube_has_tags
  braincube_has_comments
  braincube_has_assets
  braincube_has_url   :url, :generated_from => :title
  braincube_has_lock
  braincube_has_properties :properties, :seo
  braincube_has_versions :title, :abstract, :standfirst, :pullquote, :content, :footnote, :asset_link_attributes
  
  # Validations
  validates_presence_of :title, :template, :word_count, :user
  validates_presence_of :section_id, :article_type, :message => "must be specified"
  validates_presence_of :review_rating, :if => Proc.new{ review }
  validates_presence_of :starts_at, :if => Proc.new {|article| article.status == Status[:published] }

  validates :status, :presence => true, :inclusion => { :in => Article::Status::values }
  
  
  # Accessiblity
  attr_accessible :title, :abstract, :standfirst, :pullquote, :content, :section_id,
                  :footnote, :web_address, :featured, :print_only, :template,
                  :article_type, :section, :private_notes, :publication, 
                  :review, :review_rating, :starts_at, :ends_at, :writer_string, 
                  :publication_id, :associated_event_ids, :associated_venue_ids, :tag_list, :asset_ids
    
  # Callbacks
  before_save :save_word_count
  before_validation :update_review_rating
  before_validation :set_starts_at

  
  # Search
  searchable :auto_index => true, :auto_remove => true do
    text :title, :default_boost => 5
		text :stripped_title, :default_boost => 5
    text :content
    text :cached_authors
		time :search_time
    boolean(:active){ live? }
  end
	def search_time
		starts_at || created_at
	end
  
  # Special method generation for ratings
  Braincube::Config::ArticleTypes.each_pair do |k,v|
    attr_accessor "review_#{k}", "review_rating_#{k}"
    define_method "review_rating_#{k}" do
      instance_variable_get("@review_rating_#{k}") || review_rating
    end
    define_method "review_#{k}" do
      instance_variable_get("@review_#{k}") || review
    end
    attr_accessible "review_#{k}", "review_rating_#{k}"
  end
  
  def update_review_rating    
    if article_type && respond_to?("review_rating_#{ article_type }")
      self.review_rating = self.send("review_rating_#{ article_type }")
      self.review = self.send("review_#{ article_type }")   
    end
    return true
  end

  
  
  # Class methods
  ############################################################################

  class << self
  
    def recently_updated( number = nil )
      a = active.order("articles.updated_at DESC")
      number ? a.limit(number) : a
    end
    
    def unsubmitted
      where(:status=>Status[:unsubmitted]).order("articles.updated_at DESC")
    end

    def editing
      where(:status=>Status[:editing]).order("articles.updated_at DESC")
    end
    
    def subediting
      where(:status=>Status[:subediting]).order("articles.updated_at DESC")
    end
    
    def ready
      a = where(
        "status='#{Status[:ready]}' OR "+
        "(status='#{Status[:published]}' AND starts_at >= ?)", Time::now
      )
      a.order("articles.updated_at DESC")
    end
    
    def inactive
      a = where(
        "status='#{Status[:published]}' AND "+
        "( print_only=1 OR ( (NOT(ends_at IS NULL )) AND ends_at <=? ) )", Time::now
      )
      a.order("articles.updated_at DESC")
    end
    
    def downloadable
      a = where( 
        "status='#{Status[:ready]}' OR status='#{Status[:published]}'"
      )
      a.order("articles.updated_at DESC")
    end
    
    def active
      where("NOT status=?", Article::Status[:removed])
    end
    
    def live
      where(
        "status=? AND (starts_at IS NULL OR starts_at <= ?) AND "+
        "(ends_at IS NULL OR ends_at >= ?) AND print_only=?", 
        Status[:published], Time::now, Time::now, false
      )
    end
    
    def latest
      order("starts_at DESC")
    end
    
  end


  # Instance methods
  ############################################################################
  
  def stripped_title
		return title.gsub(/[^(\w|\s)]/i, "")
	end
	
  def queue
    case status
    when Status[:unsubmitted]
      return :unsubmitted
    when Status[:editing]
      return :editing
    when Status[:subediting]
      return :subediting
    when Status[:ready]
      return :publishing
    when Status[:published]
      return :publishing if (starts_at && starts_at >= Time::now)
      return :inactive if (print_only || (ends_at && ends_at<=Time::now))
      return :live
    end
    return nil
  end
  
  def removed?
    status==Article::Status[:removed]
  end
  
  def live?
    return queue == :live
  end
  
  
  def stage_complete!
    
    case status
      when Status[:unsubmitted]
        new_status = Status[:editing]
      when Status[:editing]
        new_status = Status[:subediting]
      when Status[:subediting]
        new_status = Status[:ready]
      when Status[:ready]
        new_status = Status[:published]
        update_attribute(:starts_at, Time::now) if !starts_at
      else
        new_status = status
    end
    update_attribute(:status, new_status)
  end
  
  def publish_now!
    update_attribute(:starts_at, Time::now) if !starts_at
    update_attribute(:status, Status[:published])
  end
  
  def get_abstract
    abstract.blank? ? ( standfirst.blank? ? content : standfirst ) : abstract
  end
  
  def intro
    parts = content.split(/(\<\/p\>)/)
    return content.truncate(500) unless parts.length > 2
    out = ""
    idx = 0
    while (out.length < 500) do
      if parts[idx].blank?
        break
      else
        out << parts[idx].to_s+("</p>" if parts.length> 0)
      end
      idx += 1
    end
    return out
  end
  
  def associated_event_ids
    @associated_event_ids || event_ids.join(",")
  end
  
  def associated_venue_ids
    @associated_venue_ids || venue_ids.join(",")
  end
  
  
  # Private methods
  ############################################################################

  private
    
  def build_authors
    return if @writer_string.nil?
    
    authors.destroy_all
    
    @writer_string.split(",").map{|a| a.strip unless a.blank?}.compact.uniq.each_with_index do |author, index|
      if (user = User.where(["name LIKE ? AND NOT role=?", author, "USER"]).first)        
        authors << Author.create!(:article => self, :user => user, :sort_order => index)
      else
        authors << Author.create!(:article => self, :name => author, :sort_order => index)
      end
    end
        
    self[:cached_authors] = authors.blank? ? nil : authors.map{|a| a.display_name }.to_sentence

    @writer_string = nil
    save!
  end
  
  # Word count
  def save_word_count
    self[:word_count] = content.to_s.strip_html.split(/\s/).length
  end

  def associate_events_and_venues
    self.event_ids = self.associated_event_ids.split(",") if self.associated_event_ids
    self.venue_ids = self.associated_venue_ids.split(",") if self.associated_venue_ids
  end

  def set_starts_at
    if status == Status[:published] && !starts_at
      self[:starts_at] = Time::now
    end
  end
end

