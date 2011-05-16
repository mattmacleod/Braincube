class Author < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  # Relationships
  belongs_to :article
  belongs_to :user
  
  # Validation
  validates_presence_of :article, :sort_order
  validates_presence_of :user, :unless => Proc.new { name }
  validates_presence_of :name, :unless => Proc.new { user }
  validates_uniqueness_of :user_id, :scope => :article_id, :unless => Proc.new { name }
  validates_uniqueness_of :name, :scope => :article_id, :unless => Proc.new { user }
  
  # Sort by order attribute by default
  default_scope :order => 'sort_order ASC'
  
  
  # Instance methods
  ############################################################################
  
  def display_name
    user_id ? user.name : name
  end
  
end