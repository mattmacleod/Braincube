class Draft < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  # Relationships
  belongs_to :user
  belongs_to :item, :polymorphic => true
  
  # Validation
  validates_presence_of :item, :user, :item_data
  validates_uniqueness_of :item_id
  
  serialize :item_data
  
end