require File.dirname(__FILE__) + '/../test_helper'

class CityTest < ActiveSupport::TestCase
  
  # Metatests
  ############################################################################
  should_be_valid_with_factory

  # Model definition
  ############################################################################
  should have_many :venues
  should have_many(:performances).through(:venues)
  
  should validate_presence_of :name
  
  should have_db_index(:name).unique(true)
  
  context "a new City" do

    setup { @city = Factory(:city) }

    should validate_uniqueness_of :name

    context "with a venue" do
      setup do
        @venue = Factory(:venue, :city=>@city)
      end
      should "not destroy associated venues when destroyed" do
        @city.destroy
        assert_equal 1, Venue.count
      end
    end

  end
  
  
end