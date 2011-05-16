require File.dirname(__FILE__) + '/../test_helper'

class PublicationTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
 
  # Attributes and methods
  ############################################################################
  should have_many :articles

  # Validations
  ############################################################################
  should validate_presence_of :name
  should validate_presence_of :date_street
  should validate_presence_of :date_deadline
  

  context "existing publications" do
    setup do
      @past     = Factory(:publication, :date_deadline => 1.week.ago )
      @future   = Factory(:publication, :date_deadline => 1.year.since )
    end
  
    should "have the correct directions" do
      assert_equal(:past, @past.direction)
      assert_equal(:future, @future.direction)
    end
    
    should "produce the correct options for a select menu" do
      assert_equal [ 
        [@past.name, @past.id], [@future.name, @future.id]
      ], Publication.options_for_select
    end
    
  end
      
end