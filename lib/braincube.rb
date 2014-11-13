module Braincube

  Version = File.read( File.expand_path( File.dirname(__FILE__) + "/../VERSION" ) )

  # Load the engine if required
  unless defined?( Braincube::Application )
    require "braincube/engine" 
    require "generators/braincube/setup_generator"
  end
  
  # Load external libraries. I don't quite understand why I have to do this.
  # Something screwy is going on with the load order.
  require "paper_trail"
  require "will_paginate"
  require "paperclip"
  require "tickle"
  require "sunspot_rails"
  
  # Load Braincube library files
  require "core_extensions"
  require "paperclip/cropper"
  require "braincube/export"
  require "braincube/validators"
  require "braincube/util"
  require "braincube/labelled_form_builder"
  require "braincube/node_cache"
  
  # Load model extensions
  Dir[ File.expand_path(File.dirname(__FILE__) + '/braincube/model_extensions/*.rb') ].each do |file| 
    require file 
  end

  # Setup JSON configuration
  ActiveRecord::Base.include_root_in_json = false
	
end