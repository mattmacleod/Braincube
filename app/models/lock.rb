class Lock < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  # Relationships
  belongs_to :lockable, :polymorphic => true
  belongs_to :user
  
  # Validation
  validates_presence_of :user, :lockable, :created_at, :updated_at
  validates_uniqueness_of :lockable_id, :scope => :lockable_type
  
end