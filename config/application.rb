require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  Bundler.require(*Rails.groups(:assets => %w(development test)))
end

module Braincube
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.active_support.escape_html_entities_in_json = true
    config.active_record.whitelist_attributes = false
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.assets.js_compressor = :closure
    
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
      g.test_framework :rspec, :views => false, :fixture => true
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.stylesheets false
      g.javascripts false
    end
    
    config.threadsafe! unless ENV["RAILS_THREADSAFE"] = 'off'
    
  end
end
