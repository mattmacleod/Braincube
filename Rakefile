# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Braincube::Application.load_tasks

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name        = "braincube"
    gem.summary     = "Braincube CMS engine"
    gem.version     = File.read( File.expand_path( File.dirname(__FILE__) + "/VERSION" ) )
    gem.description = "A Rails Engine that provides basic CMS functionality."
    gem.has_rdoc    = true
    gem.author      = "Matthew MacLeod"
    gem.email       = "matt@matt-m.co.uk"
    gem.homepage    = "http://braincu.be"
  end
rescue
  puts "Jeweler or one of its dependencies is not installed."
end
