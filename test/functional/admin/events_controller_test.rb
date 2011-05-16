require File.dirname(__FILE__) + '/../../test_helper'

class Admin::EventsControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct event pages" do
    assert_routing "/admin/events",                 { :controller=>"admin/events", :action=>"index" }
    assert_routing "/admin/events/new",             { :controller=>"admin/events", :action=>"new" }
    assert_routing "/admin/events/for_attachment",  { :controller=>"admin/events", :action=>"for_attachment" }
    assert_routing "/admin/events/1",               { :controller=>"admin/events", :action=>"show", :id => "1" }
    assert_routing "/admin/events/1/edit",          { :controller=>"admin/events", :action=>"edit", :id => "1" }
    assert_routing "/admin/events.csv",             { :controller=>"admin/events", :action=>"index", :format => "csv" }
  end
  
  context "when logged in as an admin user" do
    setup do
      @user = Factory(:admin_user)
      login_as @user
    end
    
    # Collection pages
    ###########################################################################
    
    context "a get to :new" do
      setup { get :new }
      should render_template :new
      should respond_with :success
      should_not set_the_flash
      should "display the new event form" do
        assert assigns(:event)
        assert assigns(:event).is_a? Event
        assert_select "input#event_title"
      end
    end
    
    context "a post to :create with invalid details" do
      setup { post :create, :event=>{:title=>""} }
      should_show_errors
      should render_template :new
      should_not set_the_flash
    end
    
    context "a post to :create with valid details" do
      setup { post :create, :event=>{ :title=>"test event" } }
      should redirect_to "/admin/events"
      should set_the_flash do /created/i end
    end
    
    context "with multiple events" do
      setup do
        @events = [ @event1 = Factory(:event, :title => "test event"), @event2 = Factory(:event, :title => "test event 2") ]
      end
      
      context "a DELETE to the event" do
        setup { delete :destroy, :id=>@event1.id }
        should respond_with :redirect
        should redirect_to "/admin/events"
        should set_the_flash do /deleted/i end
      end
      
      context "a GET to :index" do
        setup { get :index }
        should "return all events" do
          assert_same_elements @events, assigns(:events)
        end
        should "link to events" do
          assert_select "td a", "test event"
        end
      end
     
      context "an XHR GET to :index" do
        setup { xhr :get, :index }
        should "return all events" do
          assert_same_elements @events, assigns(:events)
        end
        should render_template "list"
        should_not render_template "index"
      end
      
      context "an XHR GET to :index with a query" do
        setup { xhr :get, :index, { :q => "test event 2"} }
        should "return one event" do
          assert_equal [@event2], assigns(:events)
        end
        should render_template "list"
        should_not render_template "index"
      end
      
      context "an XHR GET to :for_attachment with a query" do
        setup { xhr :get, :for_attachment, { :q => "test event 2"} }
        should "return one event" do
          assert_equal [@event2], assigns(:events)
        end
        should render_template "for_attachment"
        should_not render_template "index"
        should_not render_template "list"
      end
      
      
      # Member pages
      ###########################################################################
      
      context "a GET to the event edit page" do
        setup { get :edit, :id=>@event2.id }
        should "respond with the event editing form" do
          assert_equal @event2, assigns(:event)
        end
      end
       
      context "a GET to the event show page" do
        setup { get :show, :id=>@event2.id }
        should respond_with :redirect
      end
      
      context "a GET to a nonexistent event management page" do
        setup { get :edit, :id=>0 }
        should respond_with 404
      end
      
      context "a POST to the event update page with valid details" do
        setup { post :update, {:id=>@event2.id, :event=>{:title=>"test title"} }}
        should respond_with :redirect
        should redirect_to "/admin/events"
        should set_the_flash do /saved/i end
      end
      
      context "a POST to the event update page with invalid details" do
        setup { post :update, {:id=>@event2.id, :event=>{:title => ""}}}
        should respond_with :success
        should render_template :edit
        should_show_errors
      end      
       
    end
    
  end
  
  
end