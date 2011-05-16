class Publication < ActiveRecord::Base
  
  # Model definition
  ############################################################################

  # Relationships
  has_many :articles
  
  # Validations
  validates_presence_of :name, :date_street, :date_deadline
  
  
  class << self
    
    def options_for_select
      all.map{|p| [p.name, p.id]}
    end
    
  end
  
  # Future, current or past?
  def direction
    date_deadline < Date::today ? :past : :future
  end
  
end