class Menu < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  has_many :pages, :dependent => :destroy
  
  validates :title, :presence => true, :uniqueness => true
  validates :domain, :presence => true, :uniqueness => true

end