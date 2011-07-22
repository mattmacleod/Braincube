require File.dirname(__FILE__) + '/../test_helper'

class PageWidgetTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
 
  # Attributes and methods
  ############################################################################
  should belong_to :page
  should belong_to :widget

  # Validations
  ############################################################################
  should validate_presence_of :page
  should validate_presence_of :widget
  should validate_presence_of :sort_order
  
  should have_db_index :page_id
  should have_db_index :widget_id
  should have_db_index([:page_id, :widget_id])

end