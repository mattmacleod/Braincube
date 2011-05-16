require File.dirname(__FILE__) + '/../test_helper'

class SectionTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
 
  # Attributes and methods
  ############################################################################
  should have_many :articles
  should have_and_belong_to_many :users


  # Validations
  ############################################################################

  context "the Section class" do
    setup do
      @sections = [
        @section1 = Factory(:section, :name => "test 1"),
        @section2 = Factory(:section, :name => "test 2")
      ]
    end
    should "produce a correct list of select menu options" do
      assert_equal [ 
        ["test 1", @section1.id], ["test 2", @section2.id]
      ], Section.options_for_select
    end
    
  end

end
