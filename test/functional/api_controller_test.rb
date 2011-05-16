require File.dirname(__FILE__) + '/../test_helper'

class ApiControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct API pages" do
    assert_routing "/api/v1/users.xml", { 
      :version=>"1", :format => "xml", :controller=>"api", :action=>"users"
    }
  end
  
  
  # API doesn't require login, but check key provision
  ###########################################################################
  
  context "with an API key" do
    setup do
      @api_key = Factory(:api_key)
      @params = { :version => "1", :key => @api_key.display_code, :format=>"xml" }
    end
    
    
    # User API
    ##########################################################################
    context "and at least one user" do
      setup do 
        @user = Factory(:user, :role => "WRITER")
        @user2 = Factory(:user, :role => "PUBLISHER")
      end
      
      context "and a format type of :xml" do
        setup { @params[:format] = :xml }
      
        context "a get of an xml list of users" do
          setup do
            get :users, @params
          end
          should respond_with :success
          should respond_with_content_type :xml
          should_not render_with_layout
          should "respond with the user records" do
            assert_xml_select "users"
            assert_xml_select "id", "1"
          end
        end
    
       context "a get of an xml list of users for a specified role" do
          setup do
            get :users, @params.merge({ :role => "publisher"})
          end
          should respond_with :success
          should respond_with_content_type :xml
          should_not render_with_layout
          should "respond with the user records for that role" do
            assert_xml_select "users"
            assert_xml_select "id", "2"
          end
          should "not show users in other roles" do
            assert_xml_select "id", 1
          end
        end
          
      end   
      
    end
    
    
    
    # Events API
    ##########################################################################
    context "and events" do
      setup do 
        @city = Factory(:city, :name => "Edinburgh")
        
        @venue_1 = Factory(:venue, :tag_list => "find me", :lat=>55.9, :lng=>-3.2, :city=>@city)
        @venue_2 = Factory(:venue, :lat=>55.93, :lng=>-3.21, :city=>@city)
        @venue_3 = Factory(:venue, :lat=>55.931, :lng=>-3.211, :city=>@city)
        @venue_4 = Factory(:venue, :lat=>2, :lng=>2, :city => Factory(:city, :name => "Glasgow"))

        @events = [
          @event_1 = Factory(:event, :tag_list => "find me"),
          @event_2 = Factory(:event)
        ]
        @performance_1 = Factory(:performance, :venue => @venue_1, :event => @event_1, :starts_at => Time::utc(2010,1,1,10,0) )
        @performance_2 = Factory(:performance, :venue => @venue_2, :event => @event_2, :starts_at => Time::utc(2012,1,1,10,0) )
      end
      
      context "a get of an xml list of events" do
        setup do
          get :events, @params.merge({ :format => :xml })
        end
        should respond_with :success
        should respond_with_content_type :xml
        should_not render_with_layout
        should "respond with the event records" do
          assert_xml_select "events"
          assert_xml_select "id", "1"
          assert_xml_select "id", "2"  
        end
      end
      
      context "a get of an xml list of events with a specified start date" do
        setup do
          get :events, @params.merge({ :format => :xml, :start => "2011-10-10 10:00" })
        end
        should "respond with the correct event records" do
          assert_xml_select "events"
          assert_xml_select "id", "2"  
        end
      end
      
      context "a get of an xml list of events with a specified end date" do
        setup do
          get :events, @params.merge({ :format => :xml, :end => "2011-10-10 10:00" })
        end
        should "respond with the correct event records" do
          assert_xml_select "events"
          assert_xml_select "id", "1"  
        end
      end
      
      context "a get of an xml list of events with a specified tag" do
        setup do
          get :events, @params.merge({ :format => :xml, :tag => "find me" })
        end
        should "respond with the correct event records" do
          assert_xml_select "events"
          assert_xml_select "id", "1"  
        end
      end
      
      context "a get of an xml event" do
        setup do
          get :events, @params.merge({ :format => :xml, :id => "1" })
        end
        should "respond with the correct event record" do
          assert_xml_select "events"
          assert_xml_select "id", "1"  
        end
      end
      
      context "a get of an xml event with performances" do
        setup do
          get :events, @params.merge({ :format => :xml, :id => "1", :include_performances => "true" })
        end
        should "respond with the correct event record" do
          assert_xml_select "events"
          assert_xml_select "id", "1"  
          assert_xml_select "performances"
          assert_xml_select "performance", 1
        end
      end
      
      
      context "a get of an xml list of venues" do
        setup do
          get :venues, @params.merge({ :format => :xml })
        end
        should respond_with :success
        should respond_with_content_type :xml
        should_not render_with_layout
        should "respond with the venue records" do
          assert_xml_select "venues"
          assert_xml_select "id", "1"
          assert_xml_select "id", "2"
          assert_xml_select "id", "4"  
          assert_xml_select "id", "3"
        end
      end
      
      context "a get of an xml list of venues with a specified location" do
        setup do
          get :venues, @params.merge({ :format => :xml, :location => "55.9,-3.2,10" })
        end
        should "respond with the correct venue records" do
          assert_xml_select "venues"
          assert_xml_select "id", "1" 
          assert_xml_select "id", "2"  
          assert_xml_select "id", "3"            
        end
      end
      
      
      context "a get of an xml list of venues with a specified city" do
        setup do
          get :venues, @params.merge({ :format => :xml, :city => "Glasgow" })
        end
        should "respond with the correct venue records" do
          assert_xml_select "venues"
          assert_xml_select "id", "4"          
        end
      end
      
      
      context "a get of an xml list of venues with a specified tag" do
        setup do
          get :venues, @params.merge({ :format => :xml, :tag => "find me" })
        end
        should "respond with the correct venue records" do
          assert_xml_select "venues"
          assert_xml_select "id", "1"  
        end
      end
      
      context "a get of an xml venue" do
        setup do
          get :venues, @params.merge({ :format => :xml, :id => "1" })
        end
        should "respond with the correct venue record" do
          assert_xml_select "venue"
          assert_xml_select "venue > id", "1"  
        end
      end      
      
      context "a get of an xml venue with included performances" do
        setup do
          get :venues, @params.merge({ :format => :xml, :id => "1", :include_performances => "true" })
        end
        should "respond with the correct venue record" do
          assert_xml_select "venue"
          assert_xml_select "venue > id", "1"  
          assert_xml_select "performances"
          assert_xml_select "performance", 1
        end
      end
      
    end
    
    
    # Articles API
    ##########################################################################
    context "and articles" do
      setup do 
        @articles = [
          @article_1 = Factory(:article, :starts_at => 1.day.ago, :status => Article::Status[:published], :tag_list => "find me", :created_at => Time::utc(2011,1,1,10,0) ),
          @article_2 = Factory(:article, :starts_at => 1.day.ago, :status => Article::Status[:published], :created_at => Time::utc(2012,1,1,10,0) )
        ]
      end
    
      context "a get of an xml list of articles" do
        setup do
          get :articles, @params.merge({ :format => :xml })
        end
        should "respond with all articles" do
          assert_xml_select "articles"
          assert_xml_select "article", 2 
        end
      end
      
      context "a get of an xml list of articles with a specified tag" do
        setup do
          get :articles, @params.merge({ :format => :xml, :tag => "find me" })
        end
        should "respond with the correct article records" do
          assert_xml_select "articles"
          assert_xml_select "id", "1"  
        end
      end
      
      context "a get of an xml list of articles with a specified time" do
        setup do
          get :articles, @params.merge({ :format => :xml, :since => "2012-01-01 00:00" })
        end
        should "respond with the correct article records" do
          assert_xml_select "articles"
          assert_xml_select "id", "2"  
        end
      end
      
      context "a get of an xml article" do
        setup do
          get :articles, @params.merge({ :format => :xml, :id => "1" })
        end
        should "respond with the correct article record" do
          assert_xml_select "article"
          assert_xml_select "article > id", "1"  
        end
      end
      
    end
    
    
    # Auth
    ##########################################################################
    
    context "a request with a valid but nonexistent API key" do
      setup do
        @params = { :version => "1", :key => "#{@api_key.id}-blahblablah", :format=>"xml" }
        get :users, @params
      end
      should respond_with :forbidden
      should_not render_with_layout
    end

    context "a request with an invalid API key" do
      setup do
        @params = { :version => "1", :key => "blahblablah", :format=>"xml" }
        get :users, @params
      end
      should respond_with :forbidden
      should_not render_with_layout
    end
    
  end
  
end