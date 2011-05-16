require File.dirname(__FILE__) + '/../../test_helper'

class Admin::PagesControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct page management pages" do
    assert_routing "/admin/pages",              { :controller=>"admin/pages", :action=>"index" }
    assert_routing "/admin/pages/new",          { :controller=>"admin/pages", :action=>"new" }
    assert_routing "/admin/pages/1",            { :controller=>"admin/pages", :action=>"show", :id => "1" }
    assert_routing "/admin/pages/1/edit",       { :controller=>"admin/pages", :action=>"edit", :id => "1" }
  end
  
  context "when logged in as an admin user" do
    setup do
      @user = Factory(:admin_user)
      @menu = Factory(:menu)
      @root = Factory(:root_page)
      login_as @user
    end
    
    # Collection pages
    ###########################################################################
    
    context "a get to :new" do
      setup { get :new }
      should render_template :new
      should respond_with :success
      should_not set_the_flash
      should "display the new page form" do
        assert assigns(:page)
        assert assigns(:page).is_a? Page
        assert_select "input#page_title"
      end
    end
    
    context "a post to :create with invalid details" do
      setup { post :create, :page=>{:title=>""} }
      should_show_errors
      should render_template :new
      should_not set_the_flash
    end
    
    context "a post to :create with valid details" do
      setup { post :create, :page=>{ :title=>"test page", :url => "qwerty", :parent_id => 1 } }
      should redirect_to "/admin/pages"
      should set_the_flash do /created/i end
    end
    
    context "with multiple pages" do
      setup do
        @pages = [ @page1 = Factory(:page, :title => "test page"), @page2 = Factory(:page, :title => "test page 2") ]
      end
      
      context "a DELETE to the page" do
        setup { delete :destroy, :id=>@page1.id }
        should respond_with :redirect
        should redirect_to "/admin/pages"
        should set_the_flash do /deleted/i end
      end
      
      context "a GET to :index" do
        setup { get :index }
        should "return recent pages" do
          assert assigns(:recent_pages)
        end
        should "get the root of the tree" do
          assert_equal @root, assigns(:root)
        end
      end
     
    
      
      # Member pages
      ###########################################################################
      
      context "a GET to the page edit page" do
        setup { get :edit, :id=>@page2.id }
        should "respond with the page editing form" do
          assert_equal @page2, assigns(:page)
        end
      end
       
      context "a GET to the page show page" do
        setup { get :show, :id=>@page2.id }
        should respond_with :redirect
      end
      
      context "a GET to a nonexistent page management page" do
        setup { get :edit, :id=>0 }
        should respond_with 404
      end
      
      context "a POST to the page update page with valid details" do
        setup { post :update, {:id=>@page2.id, :event=>{  :title=>"test page", :url => "qwerty", :parent_id => 1 } }}
        should respond_with :redirect
        should redirect_to "/admin/pages"
        should set_the_flash do /saved/i end
      end
      
      context "a POST to the page update page with invalid details" do
        setup { post :update, {:id=>@page2.id, :page=>{:title => ""}}}
        should respond_with :success
        should render_template :edit
        should_show_errors
      end      
       
    end
    
  end
  
  
end