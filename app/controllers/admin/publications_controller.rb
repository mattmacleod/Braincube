class Admin::PublicationsController < AdminController
  
  layout "admin/default"
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :edit, :update, :new, :create], :roles => [:admin] }
  )
  
  # Lists
  ############################################################################
  
  def index
    @publications = Publication.order("date_street DESC")
     @publications = @publications.where(["publications.name LIKE ?", "%#{params[:q]}%"]) if params[:q]
     @publications = @publications.paginate( :page => params[:page], :per_page => Braincube::Config::AdminPaginationLimit )
     if request.xhr?
       render(:partial => "list", :locals => {:publications => @publications})
       return
     end
  end
 
   
  # Individual events
  ############################################################################
  
  def new
    force_subsection "index"
    @publication = Publication.new
    render :layout => "admin/manual_sidebar"
  end
  
  def create
    @publication = Publication.new( params[:publication] )
    if @publication.save
      flash[:notice] = "Publication has been created"
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
    @publication = Publication.find( params[:id] )
    force_subsection "index"
    render( :layout => "admin/manual_sidebar" )
  end
  
  def update
    @publication = Publication.find( params[:id] )
    @publication.attributes = params[:publication]
    if @publication.save
      flash[:notice] = "Publication has been saved"
      redirect_to( :action => :index )
    else
      force_subsection "index"
      render( :action => :edit, :layout => "admin/manual_sidebar" )
    end
  end
  
  def destroy
    @publication = Publication.find( params[:id] )
    if @publication.destroy
      flash[:notice] = "Publication deleted"
    end
    redirect_to :action => :index
  end
  
  
end
