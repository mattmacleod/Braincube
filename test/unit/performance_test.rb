require File.dirname(__FILE__) + '/../test_helper'

class PerformanceTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
 
  # Attributes and methods
  ############################################################################
  
  # Relationships
  should belong_to :user
  should belong_to :event
  should belong_to :venue
  should have_one(:city).through(:venue)
  

  # Validations
  ############################################################################
  should validate_presence_of :event
  should validate_presence_of :venue
  should validate_presence_of :user
  should validate_presence_of :starts_at

  
  # General tests
  ############################################################################
  context "Performances" do
    should "not be able to have an end date before their start date" do
      @performance = Factory.build(:performance, :ends_at => Time::utc(2009,01,01))
      assert !@performance.save
      @performance.ends_at = Time::utc(2010,02,02)
      assert @performance.save
    end
  end
  
  context "Performances in the future" do
    setup do
      @p1 = Factory(:performance, :starts_at => Time::now+1.year)
      @p2 = Factory(:performance, :starts_at => Time::now-1.week, :ends_at => Time::now+1.week)
    end
    should "be marked upcoming" do
      assert @p1.upcoming?
      assert @p2.upcoming?
    end
    should "be found in an upcoming search" do
      assert_same_elements [@p1, @p2], Performance::upcoming.all
    end
  end

  context "Performances in the past" do
    setup do
      @p1 = Factory(:performance, :starts_at => Time::now-1.year)
      @p2 = Factory(:performance, :starts_at => Time::now-1.week, :ends_at => Time::now-1.day)
    end
    should "not be marked upcoming" do
      assert !@p1.upcoming?
      assert !@p2.upcoming?
    end
    should "not be found in an upcoming search" do
      assert_equal [], Performance::upcoming.all
    end
  end
  
  context "Performances" do
    setup do
      @event = Factory(:event)
      @p1 = Factory(:performance, :event => @event)
    end
    context "when event affiliate details are set" do
      setup do
        @event.update_attribute(:affiliate_type, "EventTest")
        @event.update_attribute(:affiliate_code, "EventTestCode")
      end
      should "return affiliate event details" do
        assert_equal "EventTest", @p1.affiliate_type
        assert_equal "EventTestCode", @p1.affiliate_code
      end
      context "and performance affiliate details are set" do
        setup do
          @p1.update_attribute(:affiliate_type, "PTest")
          @p1.update_attribute(:affiliate_code, "PTestCode")
        end
        should "use performance affiliate details" do
          assert_equal "PTest", @p1.affiliate_type
          assert_equal "PTestCode", @p1.affiliate_code
        end
      end
    end
   context "and performance affiliate details are set" do
      setup do
        @p1.update_attribute(:affiliate_type, "PTest")
        @p1.update_attribute(:affiliate_code, "PTestCode")
      end
      should "use performance affiliate details" do
        assert_equal "PTest", @p1.affiliate_type
        assert_equal "PTestCode", @p1.affiliate_code
      end
    end
  end
  
  context "Performances populated with details" do
    setup do
      @city = Factory(:city, :name=>"Edinburgh")
      @venue = Factory(:venue, :title => "Test venue", :city=>@city)
      @event = Factory(:event, :title => "Test évent", :abstract => "Test abstract")
      @performance = Factory(:performance, :venue => @venue, :event => @event)
    end
    should "have correct cached values" do
      assert_equal "Test venue", @performance.cached_venue_name
      assert_equal("test_venue", @performance.cached_venue_link)
      assert_equal("Edinburgh", @performance.cached_city_name)
      assert_equal("Test évent", @performance.cached_event_name)
      assert_equal("test_event", @performance.cached_event_link)
      assert_equal("Test abstract", @performance.cached_description)
    end
    context "when changed" do
      setup do
        @performance.update_attribute(:venue, Factory(:venue, :title => "Other venue"))
      end
      should "change cached details" do
        assert_equal("Other venue", @performance.cached_venue_name)
      end
    end
  end
  
    
end