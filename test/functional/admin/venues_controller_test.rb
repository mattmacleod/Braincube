require File.dirname(__FILE__) + '/../../test_helper'

class Admin::VenuesControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct venue pages" do
    
    assert_routing "/admin/venues",           { :controller=>"admin/venues", :action=>"index" }
    assert_routing "/admin/venues/new",       { :controller=>"admin/venues", :action=>"new" }
    assert_routing "/admin/venues/1",         { :controller=>"admin/venues", :action=>"show", :id => "1" }
    assert_routing "/admin/venues/1/edit",    { :controller=>"admin/venues", :action=>"edit", :id => "1" }
    assert_routing "/admin/venues.csv",       { :controller=>"admin/venues", :action=>"index", :format => "csv" }
        
  end
  
  # Check lists
  ###########################################################################
  
  context "when logged in as an admin user" do
    setup do
      @user = Factory(:admin_user)
      login_as @user
    end
    
    context "a get to :new" do
      setup { get :new }
      should render_template :new
      should respond_with :success
      should_not set_the_flash
      should "display the new venue form" do
        assert assigns(:venue)
        assert assigns(:venue).is_a? Venue
        assert_select "input#venue_title"
      end
    end
    
    context "a post to :create with invalid details" do
      setup { post :create, :venue=>{:title=>""} }
      should_show_errors
      should render_template :new
      should_not set_the_flash
    end
    
    context "a post to :create with valid details" do
      setup { post :create, :venue=>{ :title=>"test venue" } 
      }
      should redirect_to "/admin/venues"
      should set_the_flash do /created/i end
    end
    
    context "with multiple venues" do
      setup do
        @venues = [ @venue1 = Factory(:venue, :title => "test venue"), @venue2 = Factory(:venue, :title => "test venue 2") ]
      end
      
      context "a DELETE to the venue" do
        setup { delete :destroy, :id=>@venue1.id }
        should respond_with :redirect
        should redirect_to "/admin/venues"
        should set_the_flash do /deleted/i end
      end
      
      context "a GET to :index" do
        setup { get :index }
        should "return all venues" do
          assert_same_elements @venues, assigns(:venues)
        end
        should "link to venues" do
          assert_select "td a", "test venue"
        end
      end
     
      context "an XHR GET to :index" do
        setup { xhr :get, :index }
        should "return all venues" do
          assert_same_elements @venues, assigns(:venues)
        end
        should render_template "list"
        should_not render_template "index"
      end
      
      context "an XHR GET to :index with a query" do
        setup { xhr :get, :index, { :q => "test venue 2"} }
        should "return one venue" do
          assert_equal [@venue2], assigns(:venues)
        end
        should render_template "list"
        should_not render_template "index"
      end
      
      context "a GET to the venue edit page" do
        setup { get :edit, :id=>@venue2.id }
        should "respond with the venue editing form" do
          assert_equal @venue2, assigns(:venue)
        end
      end
       
      context "a GET to the venue show page" do
        setup { get :show, :id=>@venue2.id }
        should respond_with :redirect
      end
      
      context "a GET to a nonexistent venue management page" do
        setup { get :edit, :id=>0 }
        should respond_with 404
      end
      
      context "a POST to the venue update page with valid details" do
        setup { post :update, {:id=>@venue2.id, :venue=>{:title=>"test title"} }}
        should respond_with :redirect
        should redirect_to "/admin/venues"
        should set_the_flash do /saved/i end
      end
      
      context "a POST to the venue update page with invalid details" do
        setup { post :update, {:id=>@venue2.id, :venue=>{:title => ""}}}
        should respond_with :success
        should render_template :edit
        should_show_errors
      end      
       
    end
    
  end
  
end