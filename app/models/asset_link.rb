class AssetLink < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  # Relationships
  belongs_to :asset
  belongs_to :item, :polymorphic => true
  
  # Validation
  validates_presence_of :asset, :item, :sort_order
  
  # Sort by order attribute by default
  default_scope :order => 'sort_order ASC'
  
  # Cache updates
  after_save do
    item.update_caches if item.respond_to? :update_caches
  end
  
  def get_caption
    caption.blank? ? asset.get_caption : caption
  end
  
end