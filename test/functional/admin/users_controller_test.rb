require File.dirname(__FILE__) + '/../../test_helper'

class Admin::UsersControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct user pages" do
    assert_routing "/admin/users",                { :controller=>"admin/users", :action=>"index" }
    assert_routing "/admin/users.csv",            { :controller=>"admin/users", :action=>"index", :format => "csv" }
    assert_routing "/admin/users/writers",        { :controller=>"admin/users", :action=>"writers" }
    assert_routing "/admin/users/editors",        { :controller=>"admin/users", :action=>"editors" }
    assert_routing "/admin/users/subeditors",     { :controller=>"admin/users", :action=>"subeditors" }
    assert_routing "/admin/users/publishers",     { :controller=>"admin/users", :action=>"publishers" }
    assert_routing "/admin/users/administrators", { :controller=>"admin/users", :action=>"administrators" }
    assert_routing "/admin/users/new",            { :controller=>"admin/users", :action=>"new" }
    assert_routing "/admin/users/1",              { :controller=>"admin/users", :action=>"show", :id => "1" }
    assert_routing "/admin/users/1/edit",         { :controller=>"admin/users", :action=>"edit", :id=> "1" }
  end
  
  
  # Tests for when not logged in
  ###########################################################################
  
  should_require_role :admin

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
      should "display the new user form" do
        assert assigns(:user)
        assert assigns(:user).is_a? User
        assert_select "input#user_name"
      end
    end
    
    context "a post to :create with invalid details" do
      setup { post :create, :user=>{:email=>""} }
      should_show_errors
      should render_template :new
      should_not set_the_flash
    end
    
    context "a post to :create with valid details" do
      setup { post :create, :user=>{:name=>"test", :email=>"test@example.com", :password=>"123456789"} }
      should redirect_to "/admin/users"
      should set_the_flash do /created/i end
      should have_sent_email.
        with_subject("Welcome to #{Braincube::Config::SiteTitle}").
        to('test@example.com')
    end
    
    context "with site users" do
      setup do
        @users = [
          @user,
          @writer = Factory(:user, :role=>"WRITER"),
          @editor = Factory(:user, :role=>"EDITOR"),
          @subeditor = Factory(:user, :role=>"SUBEDITOR"),
          @publisher = Factory(:user, :role=>"PUBLISHER"),
          @administrator = Factory(:user, :role=>"ADMIN", :mailing_list => false)
        ]
      end
      
      context "a GET to :index" do
        setup { get :index }
        should "return all users" do
          assert_same_elements @users, assigns(:users)
        end
      end
 
      context "a GET to :writers" do
        setup { get :writers }
        should "return only writers" do
          assert_same_elements [@writer], assigns(:users)
        end
      end

      context "a GET to :editors" do
        setup { get :editors }
        should "return only editors" do
          assert_same_elements [@editor], assigns(:users)
        end
      end
      
      context "a GET to :subeditors" do
        setup { get :subeditors }
        should "return only subeditors" do
          assert_same_elements [@subeditor], assigns(:users)
        end
      end
      
      context "a GET to :publishers" do
        setup { get :publishers }
        should "return only publishers" do
          assert_same_elements [@publisher], assigns(:users)
        end
      end
      
      context "a GET to :administrators" do
        setup { get :administrators }
        should "return only administrators" do
          assert_same_elements [@administrator, @user], assigns(:users)
        end
      end
      
      context "a GET to :mailing_list_subscribers" do
        setup { get :mailing_list_subscribers }
        should "return only mailing_list_subscribers" do
          assert_same_elements [@user, @writer, @editor, @subeditor, @publisher], assigns(:users)
        end
      end
      
      context "a GET to :index for a CSV type" do
        setup { get :index, {:format=>:csv} }
        should respond_with :success
        should respond_with_content_type :csv
        should_not render_with_layout
        should "return all users" do
          assert_same_elements @users, assigns(:users)
        end
      end
      
      context "an XHR GET to :index" do
        setup { xhr :get, :index }
        should "return all users" do
          assert_same_elements @users, assigns(:users)
        end
        should render_template "list"
        should_not render_template "index"
      end
      
      context "a GET to the user edit page" do
        setup { get :edit, :id=>@writer.id }
        should "respond with the user editing form" do
          assert_equal @writer, assigns(:user)
        end
      end
       
      context "a GET to the user show page" do
        setup { get :show, :id=>@writer.id }
        should "respond with the user information page" do
          assert_equal @writer, assigns(:user)
        end
      end
      
      context "a GET to a nonexistent user page" do
        setup { get :show, :id=>0 }
        should respond_with 404
      end
      
      context "a POST to the user update page with valid details" do
        setup { post :update, {:id=>@writer.id, :user=>{:email => "test123@example.com"}}}
        should respond_with :redirect
        should redirect_to "/admin/users"
        should set_the_flash do /saved/i end
      end
      
      context "a POST to the user update page with invalid details" do
        setup { post :update, {:id=>@writer.id, :user=>{:email => ""}}}
        should respond_with :success
        should render_template :edit
        should_show_errors
      end
      
      context "a POST to the user update page with a modified password" do
        setup { post :update, {:id=>@writer.id, :user=>{:password => "newpassword"}}}
        should respond_with :redirect
        should redirect_to "/admin/users"
        should set_the_flash do /saved/i end
        should "update the user's password" do
          @writer.reload
          assert_equal User.salted_hash("newpassword", @writer.password_salt), @writer.password_hash
        end
      end
      
       
    end
    
  end
  
  
end
