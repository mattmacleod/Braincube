class Performance < ActiveRecord::Base
    
  # Model definition
  ############################################################################
  
  # Export handlers
  braincube_set_export_columns(
    ["Venue",           :cached_venue_name],
    ["Venue ID",        :venue_id],
    ["Event",           :cached_event_name],
    ["Event ID",        :event_id],
    ["City",            :cached_city_name],
    ["Start",           :starts_at],
    ["End",             :ends_at],
    ["Price",           :price],
    ["Performer",       :performer],
    ["Drop in",         :drop_in],
    ["Ticket type",     :ticket_type],
    ["Notes",           :notes]
  )
  
  # Relationships
  belongs_to :user
  belongs_to :venue
  belongs_to :event
  has_one :city, :through => :venue
  
  # Validations
  validates_presence_of :event, :venue, :user, :starts_at
  validates_each :ends_at do |record, attr, value|
    record.errors.add attr, 'cannot be before start time' if (value && (value < record.starts_at))
  end
  
  # Cache
  before_save :update_caches
  after_save :update_event_caches
  after_destroy :update_event_caches
  
  # Attribute protection
  attr_accessible :price, :performer, :starts_at, :ends_at, :drop_in, 
                  :ticket_type, :notes, :affiliate_type, :affiliate_code,
                  :venue_id, :event_id, :venue, :event, :skip_event_cache_update
  

  # Class methods
  ############################################################################
  
  class << self
    
    def upcoming
      where("starts_at>=? OR (NOT ends_at IS NULL AND ends_at>=?)", Time::now, Time::now)
    end
    
    def in_range(time_start, time_end)
      after(time_start).before(time_end)
    end
    
    def after( the_time )
      where("starts_at>=? OR (NOT ends_at IS NULL AND ends_at>=?)", the_time, the_time)
    end
    
    def before( the_time )
      where("starts_at<=? OR (NOT ends_at IS NULL AND ends_at<=?)", the_time, the_time)
    end

		def in_city( city )
			includes(:venue).where( "venues.city_id" => city.id )
		end
    
  end


  # Instance methods
  ############################################################################
  
  def upcoming?
    return ((starts_at >= Time::now) || (ends_at && (ends_at >= Time::now)))
  end

  def affiliate_type
    return read_attribute(:affiliate_type) || (event.affiliate_type if event)
  end
  
  def affiliate_code
    return read_attribute(:affiliate_code) || (event.affiliate_code if event)
  end
  
  def date_string
    
    # No end time
    return starts_at.to_s(:listings) unless ends_at
    
    # Same day
    return "#{starts_at.to_s(:listings)} – #{ends_at.strftime("%H:%M")}" if (starts_at.beginning_of_day==ends_at.beginning_of_day)
    
    # Next day before 7am
    return "#{starts_at.to_s(:listings)} – #{ends_at.strftime("%H:%M")}" if (starts_at.beginning_of_day == (ends_at-7.hours).beginning_of_day)
    
    # Another day
    return "#{starts_at.to_s(:listings)} – #{ends_at.to_s(:listings)}"
    
  end
  
  def time_string
    return starts_at.strftime("%H:%M") unless ends_at
    return "#{starts_at.strftime("%H:%M")} – #{ends_at.strftime("%H:%M")}" if ( starts_at.beginning_of_day == ends_at.beginning_of_day )
    return "#{starts_at.strftime("%H:%M")} – #{ends_at.strftime("%H:%M")}" if ( starts_at.beginning_of_day == (ends_at-7.hours).beginning_of_day )
    return "#{starts_at.strftime("%H:%M")} – #{ends_at.to_s(:listings)}"
  end
  
  def get_description
    notes.blank? ? event.get_abstract : notes
  end
  
  def get_title
    performer.blank? ? event.title : "#{event.title} (#{performer})"
  end
  
  # Cached value updates
  ############################################################################

  def update_caches
		begin
 	   return if self.destroyed?
	    self.cached_venue_name  = venue.title
	    self.cached_venue_link  = venue.url
	    self.cached_city_name   = venue.city ? venue.city.name : nil
	    self.cached_event_name  = event.title
	    self.cached_event_link  = event.url
	    self.cached_description = event.abstract
		rescue 
		end
  end
  
  # Avoid callbacks!
  def update_event_caches
		return if skip_event_cache_update
    Event.update_all( {
      :cached_times => event.time_string, :cached_dates => event.date_string, 
      :cached_prices=> event.price_string, :cached_venues=> event.venue_string
    }, {:id=>event.id} )
  end
	attr_accessor :skip_event_cache_update
  
end
