class Widget < ActiveRecord::Base
    
  # Model definition
  ############################################################################
  
  # Relationships
  has_many :page_widgets, :dependent => :destroy
  has_many :pages, :through => :page_widgets
  
  # Validations
  validates_presence_of :title, :widget_type
  attr_accessible :title, :widget_type, :properties
  
  # Library bits
  braincube_has_properties
  braincube_has_assets
  
end