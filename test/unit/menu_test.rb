require File.dirname(__FILE__) + '/../test_helper'

class MenuTest < ActiveSupport::TestCase
  
  # Metatests
  ############################################################################
  should_be_valid_with_factory

  # Model definition
  ############################################################################
  should validate_presence_of :title

  context "a menu" do
    setup { @menu = Factory(:menu) }
    subject { @menu }
    should validate_uniqueness_of :title
    should validate_uniqueness_of :domain
  end
  
end