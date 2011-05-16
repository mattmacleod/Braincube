class Section < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  # Relationships
  has_many :articles
  has_and_belongs_to_many :users, :join_table => :owners
  
  # Validations
  validate :name, :presence => true, :uniqueness => true
  
  # Class methods
  ############################################################################
  
  class << self
    
    def options_for_select
      return all.map{|s| [s.name, s.id] }
    end
    
  end
    
end