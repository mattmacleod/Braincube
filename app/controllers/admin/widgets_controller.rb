class Admin::WidgetsController < AdminController
  
  layout "admin/default"
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :edit, :update, :new, :create], :roles => [:admin] }
  )
  
  # Lists
  ############################################################################
  
  def index
    @widgets = Widget.order("title ASC")
  end
 
   
  # Individual events
  ############################################################################
  
  def new
    force_subsection "index"
    @widget = Widget.new
    render :layout => "admin/manual_sidebar"
  end
  
  def create
    @widget = Widget.new( params[:widget] )
    if @widget.save
      flash[:notice] = "Widget has been created"
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
    @widget = Widget.find( params[:id] )
    force_subsection "index"
    render( :layout => "admin/manual_sidebar" )
  end
  
  def update
    @widget = Widget.find( params[:id] )
    @widget.attributes = params[:widget]
    if @widget.save
      flash[:notice] = "Widget has been saved"
      redirect_to( :action => :index )
    else
      force_subsection "index"
      render( :action => :edit, :layout => "admin/manual_sidebar" )
    end
  end
  
  def destroy
    @widget = Widget.find( params[:id] )
    if @widget.destroy
      flash[:notice] = "Widget deleted"
    end
    redirect_to :action => :index
  end
  
  
end
