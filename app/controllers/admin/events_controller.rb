class Admin::EventsController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :edit, :update, :new, :create], :roles => [:admin, :publisher] }
  )
  
  # Lists
  ############################################################################
  
  def index
    @events = Event.order("title ASC").includes(:performances => {:venue => :city})
    @events = @events.where(["events.title LIKE ?", "%#{params[:q]}%"]) unless params[:q].blank?
    @events = @events.paginate( :page => params[:page], :per_page => Braincube::Config::AdminPaginationLimit )
    if request.xhr?
      render(:partial => "list", :locals => {:events => @events})
      return
    end
  end
 
   
  # Individual events
  ############################################################################
  
  def new
    @event = Event.new
    render :layout => "admin/manual_sidebar"
  end
  
  def create
    @event = Event.new( params[:event] )
    @event.user = current_user
    @event.performances.each{|p| p.user = current_user unless p.user; p.event = @event }
    if @event.save
      flash[:notice] = "Event has been created"
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
    @event = Event.find( params[:id], :include => { :performances => :venue } )
    force_subsection "index"
    render( :layout => "admin/manual_sidebar" )
  end
  
  def update
    @event = Event.find( params[:id] )
    @event.attributes = params[:event]
    @event.performances.each{|p| p.user = current_user unless p.user }
    if @event.save
      flash[:notice] = "Event has been saved"
      redirect_to( :action => :index )
    else
      force_subsection "index"
      render( :action => :edit, :layout => "admin/manual_sidebar" )
    end
  end
  
  def destroy
    @event = Event.find( params[:id] )
    if @event.destroy
      flash[:notice] = "Event deleted"
    end
    redirect_to :action => :index
  end
  
  
  # Performance builder
  ############################################################################
  
  def build_performances
    @venues = Venue.find(:all)
    
    # Try to generate performances
    if request.post?
      @performance_run = PerformanceRun.new( params[:performance_run] )
      
      # Do some stuffing
      @performance_run.performance.user = User.new
      @performance_run.performance.event = Event.new
      @performance_run.performance.starts_at = Time::now

      @performances = @performance_run.get_performances
      
      # If this is a save, remove any that aren't to be saved
      if params[:commit] == "Create performances"
        @performances.select{|p| params[:performances].values.include?( p.starts_at.to_i.to_s ) }
        render :template => "/admin/events/save_performances", :layout => "admin/iframe"
        return
      end
                 
    else
      @performance_run = PerformanceRun.new( :performance => Performance.new )
    end
    
    render :layout => "admin/iframe"
    
  end
  
  
  
  # Attachment
  ############################################################################
  
  def for_attachment
    if params[:ids]
      @events = Event.where( :id => params[:ids].split(",") ).order(:title)
      render(:partial => "for_attachment", :locals => {:events => @events, :action => :remove})
    else
      @events = Event.order("title ASC").where(["events.title LIKE ?", "%#{params[:q]}%"]).limit( Braincube::Config::EventAttachmentLimit )
      render(:partial => "for_attachment", :locals => {:events => @events, :action => :add})
    end
  end
  
  
  # Importer
  ############################################################################
  
  def import
    
    # GET displays upload form
    return unless request.post?
    
    if params[:upload]
      
      # Zap existing performance import
      ImportedPerformance.zap!
      
      result = ImportedPerformance.create_from_csv!( params[:upload] )
            
      if result && !(result.first.length==0)
        flash[:notice] = "Import complete - found #{result.first.length} valid listings and #{result.last.length} invalid listings."
        redirect_to verify_import_admin_events_path
        return
      end
      
    end
    
    flash[:error] = "Import failed. Check that your CSV file is in the correct format."
    
  end
  
  def verify_import
    
    force_subsection "import"
    
    @imported_performances = ImportedPerformance.all
    
    unless request.post?
      # Display the verification list
      render :layout => "admin/manual_sidebar" and return 
    end
    
    # Save the performances
    ids_to_save = params[:import_performance].keys.map(&:to_i).uniq
    result = ImportedPerformance.convert!( ids_to_save )
    
    if result && !(result.first.length==0)
      
      saved_performances, failed_imports, new_events, updated_events = result
      
      flash[:notice] = "Import complete - saved #{saved_performances.length} listings, #{failed_imports.length} failed."
      redirect_to admin_events_path
      return
    end
    
    flash[:error] = "Import failed - No events successfully imported."
    render :layout => "admin/manual_sidebar" and return 
    
  end
  
end
