require File.dirname(__FILE__) + '/../test_helper'

class AdminControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct admin pages" do
    assert_routing "/admin",        { :controller=>"admin", :action=>"index" }
    assert_routing "/admin/setup",  { :controller=>"admin", :action=>"setup" }
    assert_routing "/admin/login",  { :controller=>"admin", :action=>"login" }
    assert_routing "/admin/logout", { :controller=>"admin", :action=>"logout" }
    assert_routing "/admin/help",   { :controller=>"admin", :action=>"help" }
    assert_routing "/admin/403",    { :controller=>"admin", :action=>"display_403" }
    assert_routing "/admin/404",    { :controller=>"admin", :action=>"display_404" }
    assert_routing "/admin/500",    { :controller=>"admin", :action=>"display_500" }
  end  
  
  # Tests for when not logged in
  ###########################################################################
  
  # Setup test
  ##############################
  context "when site is not setup" do
    context "a GET to :index" do
      setup { get :index } 
      should respond_with :redirect
      should redirect_to "/admin/setup"
    end
  end
      
  context "when not logged in" do
    
    setup do
      @user = Factory(:user)
    end
    
    # General
    ##############################
    
    context "a GET to :index" do
      setup { get :index } 
      should_require_admin_login
    end
    
    # Logging in/out
    ##############################
    
    context "a GET to :logout" do
      setup { get :logout } 
      should_require_admin_login
    end
        
    context "a GET to :login" do 
      setup { get :login } 
      should respond_with :success 
      should render_template :login 
      should_not set_the_flash
      
      should "respond with the login form" do
        assert_select "#email"
        assert_select "#password"
      end
      
    end
        
    context "a POST to :login with incorrect details" do
      setup do
        post :login, { :email => "notvalid@example.com", 
                       :password => "thisisafakepassword" }
      end
      should respond_with :success 
      should render_template :login
      should set_the_flash do /wrong/i end
    end
    
    context "a POST to :login with correct details" do
      
      setup do
        post :login, { :email => @user.email, 
                       :password => "password" }
      end
      
      should respond_with :redirect 
      should redirect_to "/admin"
      should set_the_flash do /logged in/i end
      should set_session(:user_id) { @user.id }
      
      should "assign the user to the user object" do
        assert_equal @user, assigns(:user)
      end
      
      should "update the user's access timestamp" do
        @user.reload
        assert @user.accessed_at > 1.minute.ago
      end
    end
   
    context "a POST to :login with correct details and next page specified" do
      
      setup do
        post :login, { :email => @user.email, 
                       :password => "password", :next_page => "/admin/test" }
      end
      
      should respond_with :redirect 
      should redirect_to "/admin/test"
      should set_the_flash do /logged in/i end
      should set_session(:user_id) { @user.id }
      
      should "assign the user to the user object" do
        assert_equal @user, assigns(:user)
      end
      
      should "update the user's access timestamp" do
        @user.reload
        assert @user.accessed_at > 1.minute.ago
      end
    end
    
  end


  # Tests for when logged in
  ###########################################################################
  
  context "when logged in as an admin user" do
    
    setup do
      @user = Factory(:admin_user)
      login_as @user
    end
    
    # General
    ##############################
    
    context "a GET to :index" do
      setup { get :index } 
      should respond_with :success
      should render_template :index
      should_not set_the_flash
    end
    
    context "a GET to :login" do 
      setup { get :login } 
      should respond_with :redirect 
      should redirect_to "/admin"
      should_not set_the_flash
    end
    
    context "a POST to :login" do 
      setup { post :login } 
      should respond_with :redirect 
      should redirect_to "/admin"
      should_not set_the_flash
    end
    
    context "a GET to :logout" do
      setup { get :logout }
      should respond_with :redirect
      should redirect_to "/admin/login"
      should set_the_flash do /logged out/i end
      should_not set_session(:user_id)
    end
    
    context "a GET to :help" do
      setup { get :help }
      should respond_with :success
      should render_template :help
    end
    
    
    # When logins expire
    ##############################
    
    context "and login expires" do
      setup { @user.update_attribute(:accessed_at, 100.years.ago) }
      context "a GET to :index" do
        setup { get :index }
        should respond_with :redirect
        should redirect_to "/admin/login"
        should set_the_flash do /timed out/i end
      end
    end
        
  end

  context "when logged in as a non-admin user" do
    
    setup do
      @user = Factory(:user)
      login_as @user
    end
    
    # General
    ##############################
    
    context "a GET to :index" do
      setup { get :index } 
      should respond_with :redirect
      should redirect_to "/admin/403"
    end
    
    context "a GET to :error_403" do
      setup { get :display_403 }
      should respond_with 403
      should render_template :error_403
    end
    
  end
  
end
