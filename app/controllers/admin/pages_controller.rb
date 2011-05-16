class Admin::PagesController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :edit, :update, :new, :create, :update_order], :roles => [:admin, :publisher] }
  )
  
  skip_before_filter :verify_authenticity_token, :only => [:update_order]
  
  # Lists
  ############################################################################
  
  def index
    @root = Page.root
    @updated_page ||= Page.find( flash[:updated_page_id] ) rescue nil
    @recent_pages = Page.order( "updated_at DESC" ).limit(10)
  end
 
   
  # Individual pages
  ############################################################################
  
  def new
    @page = Page.new
    
    # Some defaults
    @page.page_type = "text"
    @page.menu = Menu.first
    @page.parent_id = params[:parent_id]
    
    render :layout => "admin/manual_sidebar"
    
  end
  
  def create
    @page = Page.new( params[:page] )
    @page.user = current_user
    @page.menu = Menu.first #TODO
    @page.sort_order = @page.parent ? ((@page.parent.children.last.sort_order + 1) rescue @page.parent.sort_order+1) : 1
    if @page.save
      flush_routes
      flash[:updated_page_id] = @page.id
      flash[:notice] = "Page has been created"
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
    @page = Page.find( params[:id] )
    force_subsection "index"
    render( :layout => "admin/manual_sidebar" )
  end
  
  def update
    @page = Page.find( params[:id] )
    @page.attributes = params[:page]
    if @page.save
      flush_routes
      flash[:updated_page_id] = @page.id
      flash[:notice] = "Page has been saved"
      redirect_to( :action => :index )
    else
      force_subsection "index"
      render( :action => :edit, :layout => "admin/manual_sidebar" )
    end
  end
  
  def destroy
    @page = Page.find( params[:id] )
    if @page.destroy
      flash[:notice] = "Page deleted"
    end
    redirect_to :action => :index
  end
  
  
  # Reordering
  ############################################################################
  
  def update_order
    
    # Preload root node
    @root = Page.root
    
    # Update the parent of the page
    @page = Page.find( params[:m] )
    @page.parent_id = params[:p]
    
    # Save the page
    if @page.save
      # It saved, so update the sort order en masse
      params[:s].each_with_index do |id,idx|
        Page.find( id ).update_attribute(:sort_order, idx) rescue nil
      end
      
      # Reload the node cache
      Page.clear_nodes
      flush_routes
      updated_page = @page
      
      render :partial => "list", :status => 200, :locals => { :root => @root }
    else
      # Save failed, don't touch the sort orders
      render :partial => "list", :status => 409, :locals => { :root => @root }
    end
    
  end
  
  private
  
  def flush_routes
    Rails.application.reload_routes!
  end

end
