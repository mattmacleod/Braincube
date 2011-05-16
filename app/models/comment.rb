class Comment < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  # Relationships
  belongs_to :user
  belongs_to :item, :polymorphic => true
  
  # Validation
  validates_presence_of :item, :content
  validates_presence_of :user, :unless => Proc.new { name }
  validates_presence_of :name, :email, :ip
  
  
  # Class methods
  ############################################################################
  scope :visible, :conditions => [ "(hidden=?)", false ]
  scope :reported, :conditions => [ "reported=? AND hidden=? AND approved=?", true, false, false]
  
  
end