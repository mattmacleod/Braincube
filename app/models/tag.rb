class Tag < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  has_many :taggings
  
  validates :name, :presence=>true
  
  # Class methods
  ############################################################################
  
  class << self
    
    def find_or_create(the_string)
      f = where( ["name LIKE ?", the_string] ).first
      return f if f
      f = new( :name => the_string )
      return f if f.save
    end
    
    def popular
      Tag.group("tags.id").order("COUNT(tags.id) DESC")
    end
    
  end

  # Instance methods
  ############################################################################
  
  # Finds the items tagged with this tag
  def taggables
    taggings.map(&:taggable)
  end
  
end