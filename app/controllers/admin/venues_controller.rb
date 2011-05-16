class Admin::VenuesController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :edit, :update, :new, :create], :roles => [:admin, :publisher] }
  )
  
  # Lists
  ############################################################################
  
  def index
    @venues = Venue.includes(:city).order(:title)
    @venues = @venues.where(["venues.title LIKE ?", "%#{params[:q].downcase}%"]) if params[:q]
    respond_to do |format|
      format.js do
        @venues = @venues.paginate( :page => params[:page], :per_page => Braincube::Config::AdminPaginationLimit )
        render(:partial => "list", :locals => {:venues => @venues})
        return
      end
      format.html do
        @venues = @venues.paginate( :page => params[:page], :per_page => Braincube::Config::AdminPaginationLimit )
        render :action => "index"
        return
      end
      format.json do
        @venues = @venues.limit(10).all
        render :json => @venues.to_json
        return
      end
    end
    
  end
 
   
  # Individual users
  ############################################################################
  
  def new
    @venue = Venue.new
    render :layout => "admin/manual_sidebar"
  end
  
  def create
    @venue = Venue.new( params[:venue] )
    @venue.user = current_user
    if @venue.save
      flash[:notice] = "Venue has been created"
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
    @venue = Venue.find( params[:id] )
    force_subsection "index"
    render( :layout => "admin/manual_sidebar" )
  end
  
  def update
    @venue = Venue.find( params[:id] )
    @venue.attributes = params[:venue]
    if @venue.save
      flash[:notice] = "Venue has been saved"
      redirect_to( :action => :index )
    else
      force_subsection "index"
      render( :action => :edit, :layout => "admin/manual_sidebar" )
    end
  end
  
  def destroy
    @venue = Venue.find( params[:id] )
    if @venue.destroy
      flash[:notice] = "Venue deleted"
    end
    redirect_to :action => :index
  end
  
  def opening_times
    @venue = Venue.find( params[:id] )
    render :partial => "opening_times", :locals => { :venue => @venue }
  end
  
  
  # Attachment
  ############################################################################
  
  def for_attachment
    if params[:ids]
      @venues = Venue.where( :id => params[:ids].split(",") ).order(:title)
      render(:partial => "for_attachment", :locals => {:venues => @venues, :action => :remove})
    else
      @venues = Venue.order("title ASC").where(["venues.title LIKE ? OR venues.address_1 LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%"]).limit( Braincube::Config::VenueAttachmentLimit )
      render(:partial => "for_attachment", :locals => {:venues => @venues, :action => :add})
    end
  end
  
end
