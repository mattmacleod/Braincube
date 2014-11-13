class Admin::EventsController < AdminController
	
	# Define controller subsections
	braincube_permissions(
		{ :actions => [:index, :show, :edit, :update, :new, :create, :toggle_featured], :roles => [:admin, :publisher] }
	)
	
	# Lists
	############################################################################
	
	def index
		@events = Event.order("title ASC")
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
	
	def toggle_featured
		@event = Event.find(params[:id])
		@event.toggle!(:featured)
		render :text => @event.featured
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
			
			# If this is a save, update the performances as required and remove any that aren't selected
			if params[:commit] == "Create performances"
			  
			  # Loop through each performance. Check if it's selected based on the start time,
			  # then update the start time and add it to the output array
			  updated_performances = []
			  @performances.each do |p|
			    pp = params[:performance][p.starts_at.to_i.to_s]
		      if pp && pp[:selected]=="true"
		        p.starts_at = pp[:start]
		        p.ends_at = pp[:end]
		        updated_performances << p
	        end
		    end
		    @performances = updated_performances
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
			@events = Event.order("title ASC").where(["events.title REGEXP ?", "[[:<:]]#{params[:q]}[[:>:]]"]).limit( Braincube::Config::EventAttachmentLimit )
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


	# Exporter
	############################################################################
	
	def download
		
		respond_to do |format|
			
			format.html do
				@types = [ "Art", "Comedy", "Theatre", "Music", "Clubs"	]
			end
			
			format.indtt do
				
		#		begin
					
					# Get events and filter
					tag = Tag.find_by_name( params[:type] )
					@events = Event.tagged_with_any( tag.name )
		
					# Group correctly
					if params[:grouping]=="venue"
						@grouping = :venue
					
						# Get performances
						@events = @events.includes(:performances => :venue)

						# Filter dates
						start_time = (Date::parse( [:year, :month, :day].map{|d| params[:start_date][d]}.join("-") ).to_time + 7.hours) rescue nil
						end_time = (Date::parse( [:year, :month, :day].map{|d| params[:end_date][d]}.join("-") ).to_time + 31.hours) rescue nil
						@events = @events.after( start_time ) if start_time
						@events = @events.before( end_time ) if end_time

						# Filter city
						city = City.find( params[:city_id] ) unless params[:city_id].blank?
						@events = @events.in_city( city ) if city
					
					
						@results = @events.group_by{|e| e.venue_string( city ) }.to_a.sort_by{|a|a[0]}
					
					else
						@grouping = :date
					
						# Get performances
						@performances = Performance.includes(:venue).includes(:event).where( :event_id => @events.map(&:id) )

						# Filter dates
						start_time = (Date::parse( [:year, :month, :day].map{|d| params[:start_date][d]}.join("-") ).to_time + 7.hours) rescue nil
						end_time = (Date::parse( [:year, :month, :day].map{|d| params[:end_date][d]}.join("-") ).to_time + 31.hours) rescue nil
						@performances = @performances.after( start_time ) if start_time
						@performances = @performances.before( end_time ) if end_time

						# Filter city
						city = City.find( params[:city_id] ) unless params[:city_id].blank?
						@performances = @performances.in_city( city ) if city
					
						@results = @performances.group_by{|p| (p.starts_at-7.hours).at_beginning_of_day }.to_a.sort_by{|a|a[0]}
					end
	
					# See article controller for details...
					out_string = HTMLEntities.new.decode( 
						render_to_string.gsub("\r\n", "\n").gsub("\n+", "\n").gsub(/\t+/, "")
					)
					out_string = out_string.gsub("\n", "\r").encode("utf-16be")
			
					send_data out_string[0], 
						:disposition => "attachment; filename=listings-#{params[:type]}-#{city.name.downcase rescue "all" }.indesign.txt", 
						:type=>"text/plain; charset=utf-16be"
				
				#rescue
					
				#	flash[:error] = "Error downloading listings - please check your selected options"
	#				redirect_to :format => nil
					
	#			end
				
			end
		end
			
	end
	
end
