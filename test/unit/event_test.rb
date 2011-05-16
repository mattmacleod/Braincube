require File.dirname(__FILE__) + '/../test_helper'

class EventTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
 
  # Attributes and methods
  ############################################################################
  
  # Relationships
  should belong_to :user
  should belong_to :review
  should have_and_belong_to_many :articles
  should have_many :performances
  should have_many(:venues).through(:performances)

  # Library features
  should_have_braincube_url
  should_have_braincube_tags
  should_have_braincube_comments
  should_have_braincube_assets
  should_have_braincube_lock
  should_have_braincube_versions

  # Validations
  ############################################################################
  should validate_presence_of :title
  should validate_presence_of :user

  
  # General tests
  ############################################################################
  
  context "events in the future" do
    setup do
      @event = Factory(:event)
      @p1 = Factory(:performance, :event => @event, :starts_at => Time::now+1.year)
      @event.reload
    end
    should "be marked upcoming" do
      assert @event.upcoming?
    end
    should "be found in an upcoming search" do
      assert_same_elements [@event], Event::upcoming.all
    end
    should "be found in a ranged search" do
      assert_same_elements [@event], Event::in_range(Time::now, Time::now+2.years).all
    end
  end

  context "events in the past" do
    setup do
      @event = Factory(:event)
      @event.reload
      @p1 = Factory(:performance, :event => @event, :starts_at => Time::now-1.year)
    end
    should "not be marked upcoming" do
      assert !@event.upcoming?
    end
    should "not be found in an upcoming search" do
      assert_equal [], Event::upcoming.all
    end
    should "be found in a ranged search" do
      assert_same_elements [@event], Event::in_range(Time::now-2.years, Time::now).all
    end
  end
  
  context "events with one performance" do
    setup do
      @city = Factory(:city, :name => "Edinburgh")
      @venue = Factory(:venue, :city => @city, :title => "Test Venue")
      @event = Factory(:event)
      @event.save
      @performance = Factory(:performance, :event => @event, :starts_at => Time::utc(2020, 1, 1, 9, 0), :venue => @venue, :price => "5")
      @event.reload
    end
    should "have correct cached times" do
      assert_equal "9:00am", @event.cached_times
    end
    should "have correct cached dates" do
      assert_equal "1 Jan", @event.cached_dates
    end
    should "have correct cached prices" do
      assert_equal "£5.00", @event.cached_prices
    end
    should "have correct cached venue" do
      assert_equal "Test Venue, Edinburgh", @event.cached_venues
    end
    
    context "with an end time" do
      setup do
        @performance.update_attribute(:ends_at, Time::utc(2020,1,1,13,0))
        @event.reload
      end
      should "have correct cached times" do
        assert_equal "9:00am – 1:00pm", @event.cached_times
      end
      should "have correct cached dates" do
        assert_equal "1 Jan", @event.cached_dates
      end
    end
    
    context "with non-numeric prices" do
      setup { @performance.update_attribute(:price, "cheap"); @event.reload }
      should "have correct cached prices" do
        assert_equal "cheap", @event.cached_prices
      end
    end

    context "with a price of 0" do
      setup { @performance.update_attribute(:price, "0"); @event.reload }
      should "have correct cached prices" do
        assert_equal "free", @event.cached_prices
      end
    end
        
    context "over >1 day" do
      setup { @performance.update_attribute(:ends_at, Time::utc(2020,1,5,13,0) ); @event.reload }
      should "have correct cached times" do
        assert_equal "9:00am – 1:00pm", @event.cached_times
      end
      should "have correct cached dates" do
        assert_equal "1–5 Jan", @event.cached_dates
      end
      context "with a different end time" do
        setup { @performance.update_attribute(:ends_at, Time::utc(2020,1,5,15,0)); @event.reload }
        should "have correct cached times" do
          assert_equal "9:00am – 3:00pm", @event.cached_times
        end
        should "have correct cached dates" do
          assert_equal "1–5 Jan", @event.cached_dates
        end
      end
      context "ending in a different month" do
        setup { @performance.update_attribute(:ends_at, Time::utc(2020,2,1,15,0)); @event.reload }
        should "have correct cached dates" do
          assert_equal "1 Jan–1 Feb", @event.cached_dates
        end
      end
      context "ending in a different year" do
        setup { @performance.update_attribute(:ends_at, Time::utc(2021,2,1,15,0)); @event.reload }
        should "have correct cached dates" do
          assert_equal "1 Jan–1 Feb", @event.cached_dates
        end
      end
    end
  end
  
  
  
  context "events with multiple performances" do
    
    setup do
      @city = Factory(:city, :name => "Edinburgh")
      @venue = Factory(:venue, :city => @city, :title => "Test Venue")
      @event = Factory(:event)
      @event.save
      @performances = (1..10).map do |n|
        @performance = Factory(:performance, :event => @event, :starts_at => Time::utc(2020, 1, n, 9, 0), :venue => @venue, :price => "5")
      end
      @event.reload
    end
    
    should "have correct cached times" do
      assert_equal "9:00am", @event.cached_times
    end
    should "have correct cached dates" do
      assert_equal "1–10 Jan", @event.cached_dates
    end
    should "have correct cached prices" do
      assert_equal "£5.00", @event.cached_prices
    end
    should "have correct cached venue" do
      assert_equal "Test Venue, Edinburgh", @event.cached_venues
    end
    context "which do not happen on Sundays" do
      setup { @performances[4].destroy; @event.reload }
      should "have correct cached dates" do
        assert_equal "1–10 Jan, not Sundays", @event.cached_dates
      end
    end
    context "which do not happen on weekends" do
      setup { @performances[3].destroy && @performances[4].destroy; @event.reload }
      should "have correct cached dates" do
        assert_equal "1–10 Jan, weekdays only", @event.cached_dates
      end
    end
    context "starting and ending in different months" do
      setup do
        @performances = (1..21).map do |n|
          @performance = Factory(:performance, :event => @event, :starts_at => Time::utc(2020, 1, n+10, 9, 0), :venue => @venue, :price => "5")
        end
        @performance = Factory(:performance, :event => @event, :starts_at => Time::utc(2020, 2, 1, 9, 0), :venue => @venue, :price => "5")
        @event.reload
      end
      should "have correct cached dates" do
        assert_equal "1 Jan – 1 Feb", @event.cached_dates
      end
      context "which do not happen on weekends" do
        setup { @performances.each{|p| p.destroy if [6,0].include?(p.starts_at.wday) }; @event.reload }
        should "have correct cached dates" do
          assert_equal "1 Jan – 1 Feb, weekdays only", @event.cached_dates
        end
      end
    end
    context "and different start times" do
      setup do
        @performances.first.update_attribute(:starts_at, Time::utc(2020,1,1,10,0))
        @event.reload
      end
      should "have correct cached times" do
        assert_equal "times vary", @event.cached_times
      end
    end
    
    context "and different end times" do
      setup do
        @performances.first.update_attribute(:ends_at, Time::utc(2020,1,1,13,0))
        @event.reload
      end
      should "have correct cached times" do
        assert_equal "times vary", @event.cached_times
      end
    end

    context "and different prices" do
      setup do
        @performances.first.update_attribute(:price, "10")
        @event.reload
      end
      should "have correct cached prices" do
        assert_equal "£5.00 – £10.00", @event.cached_prices
      end
    end
      
    context "and a mixture of numeric and non-numeric prices" do
      setup do
        @performances.first.update_attribute(:price, "TBC")
        @event.reload
      end
      should "have correct cached prices" do
        assert_equal "prices vary", @event.cached_prices
      end
    end  

    context "with exclusively non-numeric prices that match" do
      setup do
        @performances.each{|p| p.update_attribute(:price, "TBC")}
        @event.reload
      end
      should "have correct cached prices" do
        assert_equal "TBC", @event.cached_prices
      end
    end
    
    context "with exclusively non-numeric prices that do not match" do
      setup do
        @performances.each{|p| p.update_attribute(:price, "TBC")}
        @performances.first.update_attribute(:price, "blah")
        @event.reload
      end
      should "have correct cached prices" do
        assert_equal "prices vary", @event.cached_prices
      end
    end

    context "with a variety of venues" do
      setup do
        @performances.first.update_attribute(:venue, Factory(:venue))
        @event.reload
      end
      should "have correct cached venues" do
        assert_equal "various venues", @event.cached_venues
      end
    end

  end
  
  # This checks weirder date formats
  context "events with multiple performances dispersed in time" do
    
    setup do
      @city = Factory(:city, :name => "Edinburgh")
      @venue = Factory(:venue, :city => @city, :title => "Test Venue")
      @event = Factory(:event)
      @event.save
      @performances = (1..5).map do |n|
        @performance = Factory(:performance, :event => @event, :starts_at => Time::utc(2020, 1, n*2, 9, 0), :venue => @venue, :price => "5")
      end
      @event.reload
    end
    should "have correct cached dates" do
      assert_equal "2–10 Jan, not 3, 5, 7, 9", @event.cached_dates
    end
    context "dispersed over two months" do
      setup do
        @performances.first.update_attribute(:starts_at, Time::utc(2020, 2, 1, 9, 0))
        @event.reload
      end
      should "have correct cached dates" do
        assert_equal "4 Jan, 6 Jan, 8 Jan, 10 Jan, 1 Feb", @event.cached_dates
      end
    end
    context "over more than a reasonable length" do
      setup do
        @performances2 = (5..15).map do |n|
          @performance = Factory(:performance, :event => @event, :starts_at => Time::utc(2020, 1, n*2, 9, 0), :venue => @venue, :price => "5")
        end
        @event.reload
      end
      should "have correct cached dates" do
        assert_equal "various dates between 2 Jan and 30 Jan", @event.cached_dates
      end
    end
  end
  
  context "events with two performances starting on the same day and ending on different days" do
    setup do
      @city = Factory(:city, :name => "Edinburgh")
      @event = Factory(:event)
      @event.save
      @p1 = Factory(:performance, :event => @event, :starts_at => Time::utc(2029,1,1,9,0), :ends_at => Time::utc(2029,1,2,9,0))
      @p2 = Factory(:performance, :event => @event, :starts_at => Time::utc(2029,1,1,9,0), :ends_at => Time::utc(2029,1,3,9,0))
      @event.reload
    end
    should "have correct cached dates" do
      assert_equal "dates vary", @event.cached_dates
    end
  end
  
end