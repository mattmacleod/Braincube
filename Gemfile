source 'http://rubygems.org'

gem 'rails', '~>3.2'

# Back-end
gem "will_paginate"
gem "paper_trail"
gem "htmlentities", "4.2.2"
gem "zip",          "2.0.2"
gem "chronic",      "0.3.0"
gem "tickle",       "0.1.7"
gem "sunspot_rails"
gem "iconv"

# Front-end
gem "haml"
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem "compass-rails"
  gem 'closure-compiler'
end

# Need to require the correct name
gem "mime-types",   "1.16", :require => "mime/types"

# Gems from Git
gem "lapluviosilla-tickle", 
  :git => "https://github.com/lapluviosilla/tickle.git", 
  :require => "tickle"
    
		
gem 'paperclip'
        
# Development only
group :development do
  gem "jeweler"
  gem "sunspot_solr"
end
  
# Testing only
group :test do
  gem "shoulda"
  gem "factory_girl_rails"
  gem "rmagick"
end
