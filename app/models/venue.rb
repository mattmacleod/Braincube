class Venue < ActiveRecord::Base
  
  # Distance values are in miles
  EARTH_RADIUS_IN_MILES = 3963.19
  MILES_PER_LATITUDE_DEGREE = 69.1
  PI_DIV_RAD = 0.0174
  LATITUDE_DEGREES = EARTH_RADIUS_IN_MILES / MILES_PER_LATITUDE_DEGREE  
  
  # Model definition
  ############################################################################
  
  # Export handlers
  braincube_set_export_columns(
    ["ID",              :id],
    ["Address",         Proc.new{|v| [v.address_1,v.address_2].select{|a| !a.blank?}.join(", ") }],
    ["City",            Proc.new{|v| v.city.name if v.city}],
    ["Postcode",        :postcode],
    ["Phone",           :phone],
    ["Email",           :email],
    ["Web",             :web],
    ["Abstract",        :abstract],
    ["Description",     :content],
    ["Featured",        :featured],
    ["Location",        Proc.new{|v| [v.lat, v.lng].join(",")} ]
  )
  
  # Relationships
  belongs_to :user
  belongs_to :city
  has_many :performances, :dependent => :destroy
  has_many :events, :through => :performances
  has_and_belongs_to_many :articles
  
  # Validations
  validates :title, :presence => true
  validates :user, :presence => true
  validates :user, :presence => true
  validates :email, :format => { :with => Braincube::Config::EmailRegexp }, :if => Proc.new{ !email.blank? }
  validates :url, :presence => true, :url => true
  
  # Library stuff
  braincube_has_tags
  braincube_has_comments
  braincube_has_assets
  braincube_has_lock
  braincube_has_url   :url, :generated_from => :title
  braincube_has_versions :title, :abstract, :content
  braincube_has_properties :seo
  
  # Opening times
  serialize :opening_hours
  
  # Accessible - most
  attr_accessible :title, :address_1, :address_2, :city_id, :postcode, :phone,
                  :email, :web, :abstract, :content, :featured, :enabled, 
                  :lat, :lng, :venue_opening_hours
  
  # Search
  searchable :auto_index => true, :auto_remove => true do
    text :title, :boost => 10
		text :stripped_title, :boost => 10
    text(:address){ address_elements.join(", ") }
    text :phone
    text :email
    text :content
		time :search_time
    boolean(:active){ enabled }
  end
  def search_time
		created_at
	end
	
  # Class methods
  ############################################################################
  
  class << self
    
    def in_region(lat, lng, radius = 5)
      select("venues.*, #{distance_query_string(lat, lng)}").
      where("NOT lat IS NULL").
      having("distance<#{radius}").
      group("venues.id").order("distance ASC")
    end
    
    def options_for_select
      @options_for_select ||= includes(:city).map{|v| [v.admin_summary, v.id] }
    end
    
    def enabled
      where(:enabled => true)
    end
    
    def with_location
      where("NOT (lat IS NULL OR lng IS NULL)")
    end
    
  end


  # Instance methods
  ############################################################################
  def stripped_title
		return title.gsub(/[^(\w|\s)]/i, "")
	end
		 
  def has_location?
    return !lat.nil? && !lng.nil?
  end
  
  def nearby
    return nil unless has_location?
    self.class.select("venues.*, #{self.class.distance_query_string(lat, lng)}").
      where("NOT venues.id=#{id}").where("NOT lat IS NULL").where("city_id=#{city_id}").
      group("venues.id").order("distance ASC")
  end
  
  def distance_from(other_venue)
    return nil unless has_location?
    v = self.class.select("#{self.class.distance_query_string(lat, lng)}").
      where("venues.id=#{other_venue.id}").where("NOT lat IS NULL").first.distance
  end
  
  def address_elements
    [address_1, address_2, (city.name if city), postcode].select{|e| !e.blank? }
  end
  
  def city_name
    city.name if city
  end
  
  def get_abstract
    abstract.blank? ? content : abstract
  end
  
  def admin_summary
    [ title, address_1, (city.name if city)].select{|e| !e.blank? }.join(", ")
  end
  
  # Opening hours
  def venue_opening_hours
    return opening_hours || {}
  end
  
  def venue_opening_hours=(val)
    oh = Hash.new
    val.each_pair do |key,value|
      oh[key] = (value.blank? ? "" : Chronic::parse( value ).strftime("%H:%M") rescue nil)
    end
    self.opening_hours = oh
  end
  
  # Determines if this venue is probably open at the specified time
  def open_at?( datetime )
    
    # Get the day, then the open and closing times. Also get the times
    # from the previous day to determine if the venue was open over midnight
    # and thus may affect today's opening hours.
    day            = datetime.strftime("%A").downcase
    previous_day   = (datetime - 1.day).strftime("%A").downcase
    
    open           = opening_hours["#{day}_open"]
    close          = opening_hours["#{day}_close"]
    previous_open  = opening_hours["#{previous_day}_open"]
    previous_close = opening_hours["#{previous_day}_close"]

    # There is no opening on this day unless there is an open and close
    # time, or there is a close time from the previous day.
    return nil unless (open && close) || (previous_open && previous_close)

    # Create some real datetimes we can use for comparison
    begin
      
      day            = datetime.midnight
      previous_day   = (datetime-1.day).midnight
      
      open           = open.blank? ? nil : Time::parse(day.strftime("%Y-%m-%d #{open} UTC"))
      close          = close.blank? ? nil : Time::parse(day.strftime("%Y-%m-%d #{close} UTC"))
      previous_open  = previous_open.blank? ? nil : Time::parse(previous_day.strftime("%Y-%m-%d #{previous_open} UTC"))
      previous_close = previous_close.blank? ? nil : Time::parse(previous_day.strftime("%Y-%m-%d #{previous_close} UTC"))
      
      # If the close time is before the start time, we need to add 1 day
      # to the close time (because we're running overnight)
      if (open && close) && (close < open)
        close = close + 1.day
      end
      
      # If the previous day's close is before open, then we need to get the 
      # close time too - and add a day to it. It will affect opening times
      # for today.
      if (previous_open && previous_close) && (previous_close < previous_open)
        previous_close = previous_close + 1.day
      else
        previous_close = nil
      end
      
    rescue
      return nil
    end
    
    # Either we're in the rage for today, or within the range from yesterday.
    return ( (open && close) && ( datetime >= open ) && ( datetime < close )) || (previous_close && (datetime < previous_close))
  
  end
  
  
  # Private methods
  ############################################################################
  
  private
  
  # Get the distance query string
  def self.distance_query_string(lat, lng)
    lat_degree_units,lng_degree_units = decode_flat_distance(lat)
    lat_dist = "#{lat_degree_units}*(#{lat} - lat)"
    lng_dist = "#{lng_degree_units}*(#{lng} - lng)" 

    min_factor = 0.415
    max_factor = 0.945
    lat_dist = "abs(#{lat_dist})"
    lng_dist = "abs(#{lng_dist})"
    
    case connection.adapter_name.downcase.to_sym
      when :sqlite
        sql = "(min(#{lat_dist},#{lng_dist})*0.415 + max(#{lat_dist},#{lng_dist})*0.945) AS distance"
      else
        sql = "(least(#{lat_dist},#{lng_dist})*0.415 + greatest(#{lat_dist},#{lng_dist})*0.945) AS distance"
    end
    
  end
  
  def self.decode_flat_distance(lat)
    lat_degree_units = MILES_PER_LATITUDE_DEGREE
    lng_degree_units = (LATITUDE_DEGREES * Math.cos(lat * PI_DIV_RAD)).abs
    [lat_degree_units, lng_degree_units]
  end
        
end