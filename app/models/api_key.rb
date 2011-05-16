class ApiKey < ActiveRecord::Base

  # Model definition
  ############################################################################
  has_many :api_requests
  attr_accessible :name
  
  # Validations
  validates_presence_of :code, :name, :permission

  # Setup an API code for new records
  before_validation :create_code, :on => :create


  # Instance methods
  ############################################################################
  
  def requests
    return api_requests
  end
  
  def record!( url, status, ip, version=0 )
    return api_requests.create( 
      :api_version=>version, :url=>url, :ip=>ip, :api_key => self, :status=>status
    )
  end
  
  def display_code
    return "#{id}-#{code}"
  end
  
  private
  
  def create_code
    self.code = random_string(64)
  end
  
end