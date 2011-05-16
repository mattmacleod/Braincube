class Widget < ActiveRecord::Base
    
  # Model definition
  ############################################################################
  
  # Relationships
  has_many :page_widgets
  has_many :pages, :through => :page_widgets
  
  # Validations
  validates_presence_of :title, :widget_type, :properties
  attr_accessible :title, :widget_type
  
  # Library bits
  braincube_has_properties
  braincube_has_assets
  
end