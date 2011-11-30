class ImportedPerformance < ActiveRecord::Base
  
  # Model definition
  ############################################################################

  # Relationships
  belongs_to :venue
  belongs_to :city
  belongs_to :event
  
  # Instance methods
  ############################################################################
  def valid_import?
    return venue && event_name && parsed_start && parsed_end
  end
  
  # Class methods
  ############################################################################
  
  class << self
    
    
    # The CSV import
    ##########################################################################
    
    def create_from_csv!( csv_data )
            
      succeeded = []
      failed    = []

      # Prepare the CSV. We'll put everything in rows >= 8 in the rows array,
      # and row 7 in the headers array.
      @rows    = []
      @headers = []

      idx = 0
      
      begin
        FasterCSV.parse(Iconv.iconv('utf-8', 'Windows-1252', csv_data.read).to_s, {:skip_blanks => true, :headers => false}) do |row|
          idx += 1
          
          if idx < 7
            next
          elsif idx==7
            @headers = row
          else
            @rows << row
          end
          
        end
              
      rescue FasterCSV::MalformedCSVError 
        return false
      end

      # Loop through each performance in the CSV and import it
      @rows.each do |row|

        begin
          
          data = {
            :event_name        => row[@headers.index("EVENT NAME")],
            :performer_name    => row[@headers.index("PERFORMER NAME")],
            :short_description => row[@headers.index("SHORT DESCRIPTION")],
            :long_description  => row[@headers.index("LONG DESCRIPTION")],
            :venue_name        => row[@headers.index("VENUE NAME")],
            :city              => row[@headers.index("CITY")],
            :price             => row[@headers.index("PRICE")],
            :start_date        => row[@headers.index("START DATE")],
            :end_date          => row[@headers.index("END DATE")],
            :start_time        => row[@headers.index("START TIME")],
            :end_time          => row[@headers.index("END TIME")],
            :tickey_type       => row[@headers.index("TICKET TYPE")],
            :category          => row[@headers.index("CATEGORY")],
            :keywords          => row[@headers.index("KEYWORDS")],
            :notes             => row[@headers.index("NOTES")],
            :featured          => row[@headers.index("FEATURED?")]
          }

          next if data[:event_name].blank?

          # Do some transformation of the data into a set of ImportedPerformance
          # attributes as required
          
          event    = Event.find_by_title( data[:event_name] )
          city     = City.find_by_name(data[:city]) || City.first
          venue    = Venue.find(:first, :conditions => { :title => data[:venue_name], :city_id => city.id})
          start_at = Time::parse( "#{data[:start_date]} #{data[:start_time]}").getlocal rescue nil
					if data[:end_date].blank?
						end_at   = Time::parse( "#{data[:start_date]} #{data[:end_time]}" ).getlocal rescue nil
          else
	          end_at   = Time::parse( "#{data[:end_date]} #{data[:end_time]}" ).getlocal rescue nil
					end
          end_at = (end_at + 1.day) if end_at  && start_at && (end_at < start_at)
          
          # Bit of a hack to account for DST
          if start_at.dst?
            start_at += 1.hour
            end_at += 1.hour if end_at
          end
          
          imported_attributes = {
            :event_name        => data[:event_name],
            :event             => event,
            :performer_name    => data[:performer_name],
            :short_description => data[:short_description],
            :long_description  => data[:long_description],
            :venue_name        => data[:venue_name],
            :venue             => venue,
            :city_name         => data[:city],
            :city              => city,
            :price             => data[:price],
            :start_date        => data[:start_date],
            :end_date          => data[:end_date],
            :start_time        => data[:start_time],
            :end_time          => data[:end_time],
            :parsed_start      => start_at,
            :parsed_end        => end_at,
            :ticket_type       => data[:ticket_type],
            :category          => data[:category],
            :keywords          => data[:keywords],
            :notes             => data[:notes],
            :featured          => (data[:featured].to_s.downcase=="yes")
          }

          # Try to create the ImpP
          imported_performance = self.new( imported_attributes )
          if imported_performance.save
            succeeded << imported_performance
          else
            failed << imported_performance
          end
          
        rescue
          next
        end
            
      end
      
      return succeeded, failed
      
    end
    
    
    # Convert placeholders to real listings
    ############################################################################
    
    def convert!( selected_ids )
      
      # Set up
      saved_performances  = []
      failed_imports      = []
      new_events          = []
      updated_events      = []
      
      system_user = User.first
      
      # Get all of the imported performances
      to_import = self.find(:all, :conditions => { :id => selected_ids })
            
      # Loop through them
      to_import.each do |import|
        
        begin
          transaction do
          
            # Load or create an event
            event = import.event
            event ||= Event.find_or_create_by_title( import.event_name )
        
            # Update the event attribtues
            event.abstract = event.short_content = import.short_description unless import.short_description.blank?
            event.content  = import.long_description unless import.long_description.blank?
            event.featured = import.featured
            event.tag_list = [event.tag_list, import.category, import.keywords].select{|k| !k.blank?}.flatten.join(", ")
            
            event.user     ||= system_user 

            event.save!

            if event.new_record?
              new_events << event
            else
              updated_events << event
            end
        
            # Setup the performance details
            performance = Performance.new(
              :event       => event,
              :venue       => import.venue,
              :price       => import.price,
              :performer   => import.performer_name,
              :starts_at   => import.parsed_start,
              :ends_at     => import.parsed_end,
              :ticket_type => import.ticket_type,
              :notes       => import.notes
            )
         
            performance.user = system_user
            
            performance.save!
            
            saved_performances << performance
          end
        rescue
          failed_imports << import
        end
        
      end

			# Force an index
			Sunspot.index( new_events + updated_events )

      return saved_performances, failed_imports, new_events, updated_events
      
    end
    
    
    def zap!
      # Erase all imps
      self.destroy_all
    end
    
  end
  
end
