source 'http://rubygems.org'

gem 'rails', '3.0.19'

# Essentials
gem "haml"
gem "fastercsv",    "1.5.3"
gem "htmlentities", "4.2.2"
gem "zip",          "2.0.2"
gem "chronic",      "0.3.0"
gem "tickle",       "0.1.7"
gem "sunspot_rails"

gem "paper_trail",  "2.0.1"
gem "will_paginate", "3.0.pre2"
gem "compass",      ">=0.12"
gem "sass",         "~>3.2.0.alpha"

# Need to require the correct name
gem "mime-types",   "1.16", :require => "mime/types"

# Gems from Git
gem "lapluviosilla-tickle", 
  :git => "https://github.com/lapluviosilla/tickle.git", 
  :require => "tickle"
    
		
gem 'paperclip',
    :git => "http://github.com/mattmacleod/paperclip.git"
        
        
# Development only
group :development do
  gem "jeweler"
end
  
# Testing only
group :test do
  gem "shoulda"
  gem "factory_girl_rails"
  gem "rmagick"
end

# Development database
group :development, :test do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem "jammit"
end