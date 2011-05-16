require File.dirname(__FILE__) + '/../test_helper'

class VenueTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
 
  # Attributes and methods
  ############################################################################
  
  # Relationships
  should belong_to :user
  should belong_to :city
  should have_many :performances
  should have_many(:events).through(:performances)
  should have_and_belong_to_many :articles

  # Custom bits
  should_have_braincube_tags
  should_have_braincube_comments
  should_have_braincube_assets
  should_have_braincube_lock
  should_have_braincube_url :url, :generated_from => :title
  should_have_braincube_versions

  # Validations
  ############################################################################
  should validate_presence_of :title
  should validate_presence_of :user
  should_validate_email :email

  
  # Location tests
  ############################################################################
  context "a Venue without a location" do
    setup { @venue = Factory(:venue) }
    subject { @venue }
    should "not be marked as having a location" do
      assert !@venue.has_location?
    end
    context "without opening hours being set" do
      should "have an opening hours hash" do
        assert @venue.venue_opening_hours.is_a?( Hash )
      end
      should "have no values in the hash" do
        assert_nil @venue.venue_opening_hours[:monday_open]
      end
    end
    
    context "when opening hours are set" do
      setup do
        @venue.update_attribute(:venue_opening_hours, {"monday_open" => "09:00", "monday_close" => "17:30"})
      end
      should "have correct opening hours" do
        assert @venue.venue_opening_hours["monday_open"]
      end
      should "correctly determine if venue is open" do
        assert @venue.open_at?( Time::utc(2011,4,25,13,0) ) # Monday at 13:00        
      end
      should "correctly determine if venue is closed" do
        assert !@venue.open_at?( Time::utc(2011,4,25,19,0) ) # Monday at 19:00
        assert !@venue.open_at?( Time::utc(2011,4,26,13,0) ) # Tuesday at 13:00
      end
    end
    
    context "when opening hours are over midnight" do
      setup do
        @venue.update_attribute(:venue_opening_hours, {"monday_open" => "09:00", "monday_close" => "03:00"})
      end
      should "correctly determine if venue is open" do
        assert @venue.open_at?( Time::utc(2011,4,26,1,0) ) # Tuesday at 01:00 
        assert @venue.open_at?( Time::utc(2011,4,25,23,0) ) # Monday at 23:00        
      end
      should "correctly determine if venue is closed" do
        assert !@venue.open_at?( Time::utc(2011,4,26,4,0) ) # Tuesday at 04:00
        assert !@venue.open_at?( Time::utc(2011,4,26,23,0) ) # Tuesday at 23:00
        assert !@venue.open_at?( Time::utc(2011,4,25,1,0) ) # Monday at 01:00 
      end
    end
    
    context "with dodgily formatted opening times" do
      setup do
        @venue.update_attribute(:venue_opening_hours, {"monday_open" => "9am", "monday_close" => "midnight"})
      end
      should "correctly determine if venue is open" do
        assert @venue.open_at?( Time::utc(2011,4,25,13,0) ) # Monday at 13:00        
      end
      should "correctly determine if venue is closed" do
        assert !@venue.open_at?( Time::utc(2011,4,25,8,0) ) # Monday at 8:00
        assert !@venue.open_at?( Time::utc(2011,4,26,23,0) ) # Tuesday at 23:00
      end
    end
    
  end
  
  context "a collection of Venues with locations" do
    setup do
      @city = Factory(:city)
      @venue1 = Factory(:venue, :lat=>55.9, :lng=>-3.2, :city=>@city)
      @venue2 = Factory(:venue, :lat=>55.93, :lng=>-3.21, :city=>@city)
      @venue3 = Factory(:venue, :lat=>55.931, :lng=>-3.211, :city=>@city)
      @venue4 = Factory(:venue, :lat=>2, :lng=>2)
    end
    should "be marked as having locations" do
      [@venue1, @venue2, @venue3, @venue4].each{|v| assert v.has_location? }
    end
    should "find nearby venues in the same city" do
      assert_same_elements [@venue2, @venue3], @venue1.nearby.all
      assert_same_elements [@venue1, @venue2], @venue3.nearby.all
      assert_same_elements [@venue1, @venue3], @venue2.nearby.all
    end
    should "find correct distance between venues" do
      assert_in_delta 2.1, @venue1.distance_from(@venue2), 0.1
    end
    should "find venues in region ordered by distance" do
      assert_equal [@venue1, @venue2, @venue3], Venue::in_region(55.9, -3.2, 10).all
    end
  end
  
end