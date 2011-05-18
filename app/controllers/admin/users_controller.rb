class Admin::UsersController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :edit, :update, :new, :create], :roles => [:admin] },
    { :actions => [:writers], :roles => [:admin] },
    { :actions => [:editors], :roles => [:admin] },
    { :actions => [:subeditors], :roles => [:admin] },
    { :actions => [:publishers], :roles => [:admin] },
    { :actions => [:administrators], :roles => [:admin] },
    { :actions => [:mailing_list_subscribers], :roles => [:admin] }
  )
  
  # User lists
  ############################################################################
  
  def index
    
    @users ||= User.order("name ASC")
    @users = @users.where(["users.name LIKE ? OR users.email LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%"]) if params[:q]
    
    respond_to do |format|
      format.html do
        @users = @users.paginate( :page => params[:page], :per_page => Braincube::Config::AdminPaginationLimit )
        request.xhr? ? render(:partial => "list", :locals => {:users => @users}) : render(:action => :index)
        return
      end
      format.csv { send_csv @users, :users }
    end

  end
  
  def writers
    @users = User.writers.order("name ASC")
    index
  end
  
  def editors
    @users = User.editors.order("name ASC")
    index
  end
  
  def subeditors
    @users = User.subeditors.order("name ASC")
    index
  end

  def publishers
    @users = User.publishers.order("name ASC")
    index
  end
    
  def administrators
    @users = User.administrators.order("name ASC")
    index
  end

  def mailing_list_subscribers
    @users = User.mailing_list_subscribers.order("name ASC")
    index
  end
    
  
  
  # Individual users
  ############################################################################
  
  def new
    @user = User.new
    
    # Admin users should be verified by default
    @user.verified = true
    
    render :layout => "admin/manual_sidebar"
    
  end
  
  def create
    
    # Force password confirmation
    params[:user][:password_confirmation] = params[:user][:password]
    
    # Create user record
    @user = User.new( params[:user] )
    @user.role = params[:user][:role] if params[:user][:role]
    
    # Save user
    if @user.save
      flash[:notice] = "User created"
      redirect_to( :action=>:index )
    else
      force_subsection "new"
      render( :action=>:new, :layout => "admin/manual_sidebar" )
    end
    
  end
  
  
  def show
    
    @user = User.find( params[:id] )
    
    # Only render for XML - HTML reqs go right to edit page
    respond_to do |format|
      format.html { redirect_to :action => :edit }
      format.xml { render :xml => @user.to_xml }
    end
        
  end
  
  def edit
    @user = User.find( params[:id] )
    force_subsection @user.role.downcase.pluralize
    
    render :layout => "admin/manual_sidebar"
  end
  
  def update
    
    # Remove blank passwords
    if params[:user][:password].blank?
      params[:user].delete(:password)
    else
      params[:user][:password_confirmation] = params[:user][:password]
    end
    
    # Main update
    @user = User.find( params[:id] )

    @user.attributes = params[:user]
    
    # Update protected attributes
    @user.role     = params[:user][:role]      if params[:user][:role]
    
    # Save the record
    if @user.save
      flash[:notice] = "User has been saved"
      redirect_to( :action=>:index )
    else
      force_subsection @user.role.downcase.pluralize
      render( :action => :edit, :layout => "admin/manual_sidebar" )
    end
  end

  
end
