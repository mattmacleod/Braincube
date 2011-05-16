class User < ActiveRecord::Base
  
  # Model definition
  ############################################################################

  #Password hashing needs SHA1
  require 'digest/sha1'
  
  # Constants
  AuthMethods = { :hash => "Hash", :salted_hash => "SaltedHash" }
  Roles = ["USER", "WRITER", "EDITOR", "SUBEDITOR", "PUBLISHER", "ADMIN"]
  
  # Export handlers
  braincube_set_export_columns(
    ["ID",              :id],
    ["User name",       :name],
    ["Email",           :email],
    ["Role",            :role],
    ["Verified",        :verified],
    ["Enabled",         :enabled],
    ["Position",        :position],
    ["Country",         :country],
    ["Postcode",        :postcode],
    ["Date of birth",   :date_of_birth],
    ["Account created", :created_at],
    ["Account updated", :updated_at],
    ["Last visit",      :accessed_at],
    ["On mailing list", :mailing_list]
  )


  # Relationships
  has_many :authors,          :dependent => :destroy
  has_many :written_articles, :through => :authors, :class_name => "Article", :source => :article
  has_many :comments,         :dependent => :nullify
  has_many :articles
  has_many :pages
  has_many :assets
  has_many :versions, :foreign_key => "whodunnit"
  has_many :events
  has_many :performances
  has_many :venues
  has_many :locks
  has_and_belongs_to_many :sections, :join_table => :owners
  
  
  # Validations
  validates :email,         :uniqueness => true, :presence => true, :format => { :with=>Braincube::Config::EmailRegexp }
  validates :auth_method,   :presence => true, :inclusion=>{ :in => User::AuthMethods.values }
  validates :role,          :presence => true, :inclusion => { :in => User::Roles }
  validates :password_salt, :presence => true, :unless=> Proc.new{ auth_method == User::AuthMethods[:hash] }
  validates :password,      :confirmation => true, :length => { :in=>5..40 }, :if => :password_changed?
  validates :terms,         :acceptance => true
  
  validates_presence_of :password_hash, :verification_key 
                        
  # Virtual attributes
  attr_accessor :password, :password_confirmation, :terms, :no_welcome_email
  attr_accessible :email, :enabled, :verified, :name, :phone, :position,
                  :country, :postcode, :date_of_birth, :profile, :mailing_list,
                  :password, :password_confirmation
  
  # Callbacks
  before_validation :generate_verification_key, :on => :create
  after_create      :send_welcome_email, :unless => :no_welcome_email



  # Class methods
  ############################################################################

  # Scopes for roles
  scope :writers, :conditions => { :role=>"WRITER" }
  scope :editors, :conditions => { :role=>"EDITOR" }
  scope :subeditors, :conditions => { :role=>"SUBEDITOR" }
  scope :publishers, :conditions => { :role=>"PUBLISHER" }
  scope :administrators, :conditions => { :role=>"ADMIN" }
  scope :mailing_list_subscribers, :conditions => { :mailing_list => true }
  
  class << self
  
    def salted_hash(pass, salt)
       Digest::SHA1.hexdigest( pass + salt )
    end

    def unsalted_hash(pass)
       Digest::SHA1.hexdigest( pass )
    end
      
    # Returns nil if user does not exist or credentials are invalid
    def authenticate(email, pass)
      u = where([ "email=? AND enabled=?", email, true ]).first
      if !u
        return nil
      elsif u.auth_method == User::AuthMethods[:hash]
        return (User.unsalted_hash(pass.downcase) == u.password_hash) ? u : nil
      elsif u.auth_method == User::AuthMethods[:salted_hash]
        return (User.salted_hash(pass.downcase, u.password_salt) == u.password_hash) ? u : nil
      end
    end
    
    def staff
      where( "NOT role='USER' ")
    end
  
  end
  
  

  # Instance methods
  ############################################################################
  
  def to_param
    id.to_s + "-" + Braincube::Util::pretty_url( name || "Anonymous user" )
  end
  
  def password=(pass)
    @password_changed      = true
    @password              = pass.downcase
    @password_confirmation = @password_confirmation.to_s.downcase

    self.password_salt     = random_string(10) if !self.password_salt?
    self.password_hash     = User.salted_hash(@password, self.password_salt)
    self.auth_method       = User::AuthMethods[:salted_hash]
  end
  
  def reset_password!
    new_pass      = random_string(6).downcase
    self.password = self.password_confirmation = new_pass
    self.save
    UserMailer.reset_password(self, new_pass).deliver
  end
  
  
  # Private methods
  ############################################################################

  private
  
  def send_welcome_email
    UserMailer.welcome_email(self).deliver
  end
  
  def password_changed?
    return @password_changed
  end
  
  def generate_verification_key
    self.verification_key = random_string(10)
  end
  
end

