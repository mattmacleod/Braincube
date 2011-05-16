require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ManagementControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct management pages" do
    
    assert_routing "/admin/management",     { :controller=>"admin/management", :action=>"index" }
        
  end

  
end