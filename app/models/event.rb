class Event < ActiveRecord::Base
    
  # Model definition
  ############################################################################
  
  # Export handlers
  braincube_set_export_columns(
    ["ID",              :id],
    ["Title",           :title],
    ["Abstract",        :abstract],
    ["Short content",   :short_content],
    ["Content",         :content],
    ["Featured",        :featured],
    ["Affiliate type",  :affiliate_type],
    ["Affiliate code",  :affiliate_code],
    ["Times",           :cached_times],
    ["Dates",           :cached_dates],
    ["Prices",          :cached_prices],
    ["Venues",          :cached_venues]
  )
  
  # Relationships
  belongs_to :user
  has_and_belongs_to_many :articles
  has_many :performances, :order=>"starts_at ASC", :dependent => :destroy
  has_many :venues, :through => :performances
  belongs_to :review, :class_name => "Article"
  
  # Validations
  validates_presence_of :title, :user
  
  # Library stuff
  braincube_has_url   :url, :generated_from => :title
  braincube_has_tags
  braincube_has_comments
  braincube_has_lock
  braincube_has_assets
  braincube_has_versions :title, :abstract, :short_content, :content
  braincube_has_properties :seo
  
  # Need to set accessible attributes
  attr_accessible :title, :abstract, :short_content, :content, :featured, :review_id,
                  :enabled, :print, :afiliate_type, :affiliate_code, :performances_attributes
                  
  # Handle performances
  accepts_nested_attributes_for :performances, :allow_destroy => true
  
  # Search
  searchable :auto_index => true, :auto_remove => true do
    text :title, :default_boost => 5
		text :stripped_title, :default_boost => 5
    text :short_content
    text :content
    text :cached_venues
    time :search_time
    boolean(:active){ upcoming? && enabled }
  end
  def search_time
		next_performance_time
	end
	
	
	# Callbacks
	after_save :update_performance_caches
	
  # Class methods
  ############################################################################
  
  class << self
    
    def upcoming
      includes(:performances).
      where("performances.starts_at>=? OR (NOT performances.ends_at IS NULL AND performances.ends_at>=?)", Time::now, Time::now)
    end
    
    def in_range(time_start, time_end)
      after(time_start).before(time_end)
    end
  
    def enabled
      where(:enabled => true)
    end
    
    def after( the_time )
      joins(:performances).
      where("performances.starts_at>=? OR (NOT performances.ends_at IS NULL AND performances.ends_at>=?)", the_time, the_time).
			group("events.id")
    end
    
    def before( the_time )
      joins(:performances).
      where("performances.starts_at<=? OR (NOT performances.ends_at IS NULL AND performances.ends_at<=?)", the_time, the_time).
			group("events.id")
    end

		def in_city( city )
			includes(:performances => :venue).where( "venues.city_id" => city.id )
		end
    
  end


  # Instance methods
  ############################################################################
  
	def live_review
		r = articles.where("review_rating > 0").first
		r if r && r.live?
	end
	
  def stripped_title
		return title.gsub(/[^(\w|\s)]/i, "")
	end
	
  def upcoming?
    self.class.upcoming.where("events.id=#{id}").count == 1
  end

  def next_performance_time
    performances.upcoming.first.starts_at rescue nil
  end
  
  def get_abstract
    abstract.blank? ? content : abstract
  end

  # The following code generates nice, human-friendly summaries of the data
  # for this event. Some of this can get quite ugly and slow, but it's all
  # cached so should only be updated when necessary (i.e. when any of the
  # associated performances change)
  
  
  # Human time - if start times or end times vary, return the appropriate 
  # string. If there's an end time, return a range, otherwise just the start
  def time_string
    
    # Get array of start times
    start_times = performances.upcoming.map do |n| 
      n.starts_at.strftime("%l:%M%p").downcase.strip 
    end.uniq
    return "times vary" unless ( start_times.length == 1 )

    # Get array of end times
    end_times = performances.upcoming.map do |n| 
      n.ends_at.strftime("%l:%M%p").downcase.strip if n.ends_at 
    end.uniq
    return "times vary" unless ( end_times.length == 1 )
        
    if end_times.any?(&:nil?)
      return start_times.first
    else
      return "#{start_times.first} – #{end_times.first}"
    end
    
  end
  
  
  
  # Human price - If all prices are the same, use that one. Otherwise try to
  # work out a range if the prices are numeric. Failing that, they vary
  def price_string
    
    prices = performances.upcoming.map(&:price).uniq
    
    # Only 1 price? Format if it's numeric, otherwise return
    if ( prices.length == 1 )
      if ( numeric?( prices.first ) )
        return price_format( prices.first.to_f )
      else
        return prices.first
      end
    else # Multiple prices? Try to find a range
      if prices.all?{|p| numeric?(p) }
        np = prices.map(&:to_f).sort
        return "#{ price_format(np.first) } – #{ price_format(np.last) }"
      else
        return "prices vary"
      end
    end
    
  end
  
  
  
  # Venue details
  def venue_string( city = nil )
    
    if city
      venues = performances.upcoming.includes(:venue).where("venues.city_id=?", city.id).map(&:venue_id).uniq
    else
      venues = performances.upcoming.map(&:venue_id).uniq
    end
    
    if venues.length==1 
      v = Venue.find( venues.first )
      return [v.title, ((v.city ? nil : v.city.name ) if city)].compact.join(", ")
    elsif venues.empty?
      return "No venue"
    else
      return "various venues"
    end
  end
  
  
  
  # Dates - weird and messy
  # TODO: Pull formatting and constants out to config file
  def date_string
    
    return unless performances.count > 0
    
    # Get all distinct start days
    start_dates = performances.upcoming.map do |n| 
      n.starts_at.midnight
    end.uniq
    
    # Get all distinct end days
    end_dates = performances.upcoming.map do |n| 
      n.ends_at.midnight if n.ends_at
    end.compact.uniq
    
    # If there is only one start date, then we should return the start date or
    # the start-end dates (if there is also an end date i.e. a multi-day event
    if (start_dates.length == 1)
      
      # No end dates, so just the start date
      if (end_dates.empty?)
        return start_dates.first.strftime("%e %b").strip
      elsif end_dates.length==1
        # If the start and end dates are the same, return
        if (start_dates.first==end_dates.first)
          return start_dates.first.strftime("%e %b").strip 
        end
        # If the start and end dates are in the same month, we only need to 
        # include the month name once, otherwise format both
        if (end_dates.first.month == start_dates.first.month)
          return start_dates.first.day.to_s + "–" + end_dates.first.day.to_s + 
                " " + start_dates.first.strftime("%b")
        else
          return start_dates.first.strftime("%e %b").strip + "–" +
          end_dates.first.strftime("%e %b").strip 
        end
        
      else
        # One start date and multiple end dates. Probably a mistake, but it 
        # might happen - don't try to hard to print anything useful
        return "dates vary"
      end
      
    elsif (start_dates.length>1)
      
      # Try to find "runs" of performances for calculating useful date info 
      start_date        = performances.upcoming.first.starts_at.midnight
      end_date          = performances.upcoming.last.starts_at.midnight
      performance_dates = performances.upcoming.map{|p| p.starts_at.midnight }.uniq
      
      # First get an array of days between start_date and end_date
      test_dates = []
      cur_date = start_date
      while cur_date<=end_date do
        test_dates << cur_date
        cur_date += 1.day
      end
      
      # Now loop through them and check that particular conditions are true
      run_type = nil
      if test_dates.all?{|d| performance_dates.include? d }
        # All days have a performance on them - consecutive run
        run_type = "" 
      elsif test_dates.all?{|d| performance_dates.include?(d) ^ d.wday==0 }
        # Sundays do not have performances
        run_type = "no_sundays"
      elsif test_dates.all?{|d| performance_dates.include?(d) ^ (d.wday==0 || d.wday==6) }
        # Weekends do not have performances
        run_type = "weekdays"
      elsif (performance_dates.length >= 4) && (test_dates.reject{|d| performance_dates.include? d }.length <= 4)
        # There are <= 4 days without performances and >=4 performances, so 
        # we list the range and days without performances
        run_type = "nearly"
      end
      
      # If we found a run (run_type is set) then render an appropriate string
      if run_type
        if (performance_dates.first.month == performance_dates.last.month)
          # Stars and ends in the same month, so render a range only
          return performance_dates.first.day.to_s + "–" +
                 performance_dates.last.day.to_s + " " + 
                 performance_dates.first.strftime("%b").strip + 
                 (", not Sundays" if run_type == "no_sundays").to_s +
                 (", weekdays only" if run_type == "weekdays").to_s +
                 (", not " + test_dates.reject{|d| performance_dates.include? d }.
                  map{|d| d.day.to_s }.join(", ") if run_type == "nearly").to_s
        else
          # Need to include month names
          return performance_dates.first.strftime("%e %b").strip + " – " +
                 performance_dates.last.strftime("%e %b").strip  +
                 (", not Sundays" if run_type == "no_sundays").to_s +
                 (", weekdays only" if run_type == "weekdays").to_s +
                 (", not " + test_dates.reject{|d| performance_dates.include? d }.
                  map{|d| d.strftime("%e %b").strip }.
                  join(", ") if run_type=="nearly"
                 ).to_s
        end
          
      elsif performance_dates.length <= 5
        # There are less than 5 dates, so just put them in a list
        return performance_dates.map{|d| d.strftime("%e %b").strip}.join(", ")
      else
        # Can't work anything out
        return "various dates between "+
        performance_dates.first.strftime("%e %b").strip + " and " +
        performance_dates.last.strftime("%e %b").strip
      end
      
    else
      return "Unknown dates"
    end
    
  end
  

  private
  
  # Formats a number into a price with precision 2
  def price_format(number)
    return "free" if number.to_f==0.to_f
    "£%01.2f" % ((Float(number.to_f) * (10 ** 2)).round.to_f / 10 ** 2)
  end

  def update_performance_caches
		performances.reject(&:destroyed?).each do |p|
			p.skip_event_cache_update = true
			p.save
		end
	end
	
end