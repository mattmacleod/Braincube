source 'http://rubygems.org'

gem 'rails', '3.0.9'

# Essentials
gem "haml",         "3.1.2"
gem "sass",         "3.1.2"
gem "fastercsv",    "1.5.3"
gem "htmlentities", "4.2.2"
gem "zip",          "2.0.2"
gem "chronic",      "0.3.0"
gem "tickle",       "0.1.7"
gem "sunspot_rails"

gem "paper_trail",  "2.0.1"
gem "will_paginate", "3.0.pre2"

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
  gem "mongrel"
  gem "cgi_multipart_eof_fix"
  gem "fastthread"
  gem "mongrel_experimental"
  gem "dr_dre"
  gem "ruby-debug"
  gem "jeweler",      "1.5.2"  
end
  
# Testing only
group :test do
  gem "autotest"
  gem "autotest-rails"
  gem "shoulda"
  gem "factory_girl_rails"
  gem "rcov"
  gem "rmagick"
end

# Development database
group :development, :test do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem "jammit"
end