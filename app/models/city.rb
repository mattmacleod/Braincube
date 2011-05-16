class City < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  has_many :venues, :dependent => :nullify
  has_many :performances, :through => :venues
  
  validates :name, :presence => true, :uniqueness => true
  
  class << self
    
    def options_for_select
      all.map{|c| [c.name, c.id]}
    end
    
    def with_upcoming
      select("cities.name, cities.id").includes(:performances).where("performances.starts_at>=?", Time::now)
    end
    
  end
  
end