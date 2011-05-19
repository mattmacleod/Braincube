class ActiveSupport::TestCase
  
  #Do a quick fake login
  def login_as(user)
    @request.session[:user_id] = user.id
  end
  
  class << self
    
    # Check that we can't access the specified page
    def should_require_admin_login 
      should respond_with :redirect 
      should redirect_to "/admin/login" 
    end
    
    # Check that this request asks for a login
    def should_require_login 
      should respond_with :redirect 
      should redirect_to "/account/login"
    end
    
    # Check that we can only access this controller with the specified roles
    def should_require_role(*roles)
    
      klass = self.name.gsub(/Test$/, '').underscore.to_sym
    
      context "when not logged in" do
        setup { @user = Factory(:user) }
        context "on GET of :index on #{klass}" do
          setup { get :index }
          should redirect_to "/admin/login" 
        end
      end

      context "when logged in as a user with no roles" do
        setup do
          @user = Factory(:user)
          login_as @user
        end
        context "on GET of :index on #{klass}" do
          setup { get :index }
          should redirect_to "/admin/403"
        end
      end

      Braincube::Config::AdminRoles.each do |role|
        context "when logged in as an user with the #{role} role" do
          setup do
            @user = Factory(:user, :role => role)
            login_as @user
          end
          context "on GET of :index on #{klass}" do
            setup { get :index }
            if roles.include?(role.downcase.to_sym)
              should respond_with :success 
              should render_template :index 
              should_not set_the_flash
            else
              should redirect_to "/admin/403"
            end
          end
        end
      end

    end
  
  end
  
end