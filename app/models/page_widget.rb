class PageWidget < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  belongs_to :page
  belongs_to :widget
  
  # Validation
  validates_presence_of :page, :widget, :sort_order
  
end