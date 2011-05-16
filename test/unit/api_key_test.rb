require File.dirname(__FILE__) + '/../test_helper'

class ApiKeyTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
  # Attributes and methods
  ############################################################################
  should have_many :api_requests
  should have_db_index(:code).unique(true)
  should_not allow_mass_assignment_of :code
  
  # Validations
  ############################################################################
  should validate_presence_of :name
  should validate_presence_of :permission
  
  # Functionality
  ############################################################################
  context "an API key" do
    setup do
      @api_key = Factory(:api_key)
    end
    subject { @api_key }
        
    context "when a request is recorded" do
      setup do
        @api_key.record!("users", 400, 1)
      end
      
      should "create a record of the request" do
        assert_equal 1, @api_key.requests.count
      end
      
    end
  end
  
  
  context "a newly-created API key" do
    setup { (@api_key = ApiKey.new).save }
    should "have a randomly generated code" do
      assert @api_key.code.to_s.length > 0
    end
    should "produce the correct display code" do
      assert_equal "#{@api_key.id}-#{@api_key.code}", @api_key.display_code
    end
  end
  
  
end