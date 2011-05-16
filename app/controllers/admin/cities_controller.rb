class Admin::CitiesController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :edit, :update, :new, :create], :roles => [:admin, :publisher] }
  )
  
  # Lists
  ############################################################################
  
  def index
    @cities = City.order("name ASC")
    @cities = @cities.where(["cities.name LIKE ?", "%#{params[:q]}%"]) if params[:q]
    @cities = @cities.paginate( :page => params[:page], :per_page => Braincube::Config::AdminPaginationLimit )
    if request.xhr?
      render(:partial => "list", :locals => {:cities => @cities})
      return
    end
  end
 
   
  # Individual events
  ############################################################################
  
  def new
    @city = City.new
    render :layout => "admin/manual_sidebar"
  end
  
  def create
    @city = City.new( params[:city] )
    if @city.save
      flash[:notice] = "City has been created"
      redirect_to( :action=>:index )
    else
      force_subsection "new"
      render( :action=>:new, :layout => "admin/manual_sidebar" )
    end
  end
  
  def show
    redirect_to :action => :edit 
  end
  
  def edit
    @city = City.find( params[:id] )
    force_subsection "index"
    render( :layout => "admin/manual_sidebar" )
  end
  
  def update
    @city = City.find( params[:id] )
    @city.update_attributes( params[:city] )
    if @city.save
      flash[:notice] = "City has been saved"
      redirect_to( :action => :index )
    else
      force_subsection "index"
      render( :action => :edit, :layout => "admin/manual_sidebar" )
    end
  end
  
  def destroy
    @city = City.find( params[:id] )
    if @city.destroy
      flash[:notice] = "City deleted"
    end
    redirect_to :action => :index
  end
  
 
end
