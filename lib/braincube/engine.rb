module Braincube
  class Engine < Rails::Engine
  
    initializer "static assets" do |app|
      app.middleware.insert_after Rack::Lock, ActionDispatch::Static, "#{root}/public"
    end
    
  end
end
