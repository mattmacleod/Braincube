class AdminController < ApplicationController
  
  helper Braincube::AdminHelper
  helper Admin::AssetsHelper
  helper Admin::ArticlesHelper
  
  # Remember that all admin controllers should inherit from this one. Need to 
  # override things that we want to change!
  
  cache_sweeper :node_sweeper
  before_filter :flush_node_cache

  # Controller setup
  ############################################################################
  
  # All actions will require a valid admin login.
  before_filter :require_admin_login, :except => [:setup, :login, :display_404, :display_403, :display_500]
  
  # General prep work
  before_filter :load_defaults
  layout "admin/default"
  
  
  
  # General controller actions
  ############################################################################

  helper "admin/articles"

  def index
        
    @articles ||= current_user.role.downcase.to_sym==:writer ? Article.where(:user_id=>current_user.id).recently_updated : Article.recently_updated
    @articles = @articles.order("articles.updated_at DESC").includes(:assets).includes(:drafts).includes(:lock).limit(20)
    
  end
  
  def help
    render :layout => "admin/wide"
  end
  
  def setup
    
    @user = User.new( :name => "Administrator" )
    
    redirect_to :index and return if (User.count > 0)
    render(:layout => "admin/notice") and return if request.get?
    
    # Create user record
    @user          = User.new( params[:user] )
    @user.role     = "ADMIN"
    @user.enabled  = true
    @user.verified = true
    
    if @user.save
      
      # Log user in
      flash[:notice] = "User created"
      session[:user_id] = @user.id
      
      # Initial setup
      # TODO: move this to a better place
      begin
        Page.transaction do
          Menu.create!(:title => "Main site", :domain => Braincube::Config::SiteBaseUrl.gsub("http://", ""))
          page = Page.new(:parent => nil, :url => "", :title => "Home")
          page.user = @user
          page.menu = Menu.first
          page.save!
          folder = AssetFolder.new(:parent => nil, :name => "Files")
          folder.save!
        end
      
      rescue
        flash[:error] = "Setup failed. Please contact an administrator."
      end
      
      redirect_to( :action => :index ) and return
      
    else
      render(:layout => "admin/notice") and return
    end

  end
  
  
  
  # Login and logout actions
  ############################################################################
  
  def login
    
    render(:nothing => true, :status => 403) and return if request.xhr?
    
    # Back to the root if we're already logged in
    redirect_to admin_path and return if logged_in?
    
    # Find out what page we're trying to reach
    @next_page = params[:next_page] || session[:next_page] || admin_path

    render :layout => "admin/notice" and return if request.get?

    @user = User.authenticate( params[:email], params[:password] )

    if @user && @user.verified
      @user.update_attribute(:accessed_at, Time::now)
      session[:user_id] = @user.id
      flash[:notice]    = "You have logged in"
      redirect_to @next_page
    else
      flash.now[:error] = "Wrong password or email address"
      render :layout => "admin/notice"
    end

  end
  
  def logout
    session[:user_id] = nil
    flash[:notice] = "You have logged out"
    redirect_to admin_login_path
  end
  
  
  
  
  # Errors
  ############################################################################
  
  # Handle 500 (other) errors, then 404s.
  rescue_from Exception, :with => :display_500
  rescue_from ActiveRecord::RecordNotFound, :with => :display_404
  
  # Custom 404 for admin
  def display_404
    render :nothing => true, :status => 404 and return if request.xhr?
    render :template => "admin/error_404", :status => 404, :layout => "admin/error"
  end
  
  # Custom 403 for admin
  def display_403
    render :nothing => true, :status => 403 and return if request.xhr?
    render :template => "admin/error_403", :status => 403, :layout => "admin/error"
  end
  
  # Custom 500 for admin
  def display_500( e )
    raise e #if Rails.env != "production"
    #render :nothing => true, :status => 500 and return unless request.format==:html && !request.xhr?
    #render :template => "admin/error_500", :status => 500, :layout => "admin/error"
  end
  
  
  # Tools, filters etc.
  ############################################################################
  
  protected 
  
  def send_csv( data, type = :export)
    send_data data.to_csv, :type =>"text/csv", :disposition => 'attachment', 
    :filename => export_filename_for(type, :csv)
  end
  
  
  #
  # Filter out non-admin logins
  #
   
  def require_admin_login
   
    # Valid user
    if current_user && (current_user.accessed_at > (Time::now - Braincube::Config::SessionTimeout))
      return is_admin?
    elsif current_user # Expired timeout
      flash[:error] = "Your session has timed out"
      session[:user_id] = nil
      session[:next_page] = request.path
      redirect_to admin_login_path and return false
    elsif (User.count > 0) # Any users
      flash[:error] = "Login to access that page"
      session[:user_id] = nil
      session[:next_page] = request.path
      redirect_to admin_login_path and return false
    else # Setup phase
      redirect_to admin_setup_path and return false
    end
    
  end
   
  
  #
  # Load some default variables that we'll need in most places
  #
  def load_defaults
    
  end
  
  
  
  #
  # Define the subsections for use in authentication and menus
  #
      
  braincube_permissions(
    { :actions => [:index], :roles => [:writer, :editor, :subeditor, :publisher, :admin] },
    { :actions => [:help], :roles => [:writer, :editor, :subeditor, :publisher, :admin] }
  )

  # Allows selected subsection tab to be forced to a particular selection
  def force_subsection( title )
    @forced_active_subsection = title
  end
    

	# Clear the node cache if required
	def flush_node_cache
    
    # Get the time of the last flush request
    flush_timestamp = File.read("#{Rails.root}/tmp/flush_node_cache.txt").to_i rescue nil
    return unless flush_timestamp
    
    unless flush_timestamp <= Braincube::NodeCache::node_flush_timestamp
			AssetFolder.clear_node_cache!
			Page.clear_nodes
			Braincube::NodeCache::node_flush_timestamp = Time::now.to_i
    end
    
  end

end
