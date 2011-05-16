require File.dirname(__FILE__) + '/../test_helper'

class WidgetTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
 
  # Attributes and methods
  ############################################################################
  should have_many :page_widgets
  should have_many :pages

  # Validations
  ############################################################################
  should validate_presence_of :title
  should validate_presence_of :widget_type
  should validate_presence_of :properties
  

end
