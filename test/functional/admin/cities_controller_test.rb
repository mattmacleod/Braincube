require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CitiesControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct city admin pages" do
    assert_routing "/admin/cities",             { :controller=>"admin/cities", :action=>"index" }
    assert_routing "/admin/cities/1",           { :controller=>"admin/cities", :action=>"show", :id => "1" }
  end
  

 # Collection pages
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
      should "display the new city form" do
        assert assigns(:city)
        assert assigns(:city).is_a? City
        assert_select "input#city_name"
      end
    end
  
    context "a post to :create with invalid details" do
      setup { post :create, :city=>{:name=>""} }
      should_show_errors
      should render_template :new
      should_not set_the_flash
    end
  
    context "a post to :create with valid details" do
      setup { post :create, :city=>{ :name => "test city" } }
      should redirect_to "/admin/cities"
      should set_the_flash do /created/i end
    end
  
    context "with multiple cities" do
      setup do
        @cities = [ @city_1 = Factory(:city, :name => "find this test city"), @city_2 = Factory(:city) ]
      end
    
      context "a DELETE to the city" do
        setup { delete :destroy, :id => @city_1.id }
        should respond_with :redirect
        should redirect_to "/admin/cities"
        should set_the_flash do /deleted/i end
      end
    
      context "a GET to :index" do
        setup { get :index }
        should "return all cities" do
          assert_same_elements @cities, assigns(:cities)
        end
        should "link to cities" do
          assert_select "td a", "find this test city"
        end
      end
   
      context "an XHR GET to :index" do
        setup { xhr :get, :index }
        should "return all cities" do
          assert_same_elements @cities, assigns(:cities)
        end
        should render_template "list"
        should_not render_template "index"
      end
    
      context "an XHR GET to :index with a query" do
        setup { xhr :get, :index, { :q => "find"} }
        should "return one city" do
          assert_equal [@city_1], assigns(:cities)
        end
        should render_template "list"
        should_not render_template "index"
      end

      # Member pages
      ###########################################################################
    
      context "a GET to the city edit page" do
        setup { get :edit, :id=>@city_2.id }
        should "respond with the city editing form" do
          assert_equal @city_2, assigns(:city)
        end
      end
     
      context "a GET to the city show page" do
        setup { get :show, :id=>@city_2.id }
        should respond_with :redirect
      end
    
      context "a GET to a nonexistent city management page" do
        setup { get :edit, :id=>0 }
        should respond_with 404
      end
    
      context "a POST to the city update page with valid details" do
        setup { post :update, {:id=>@city_2.id, :city=>{:name=>"test city"} }}
        should respond_with :redirect
        should redirect_to "/admin/cities"
        should set_the_flash do /saved/i end
      end
    
      context "a POST to the city update page with invalid details" do
        setup { post :update, {:id=>@city_2.id, :city=>{:name => ""}}}
        should respond_with :success
        should render_template :edit
        should_show_errors
      end      
     
    end
  
  end
  
end