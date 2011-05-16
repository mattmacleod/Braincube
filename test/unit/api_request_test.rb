require File.dirname(__FILE__) + '/../test_helper'

class ApiRequestTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
  # Attributes and methods
  ############################################################################
  should belong_to :api_key
  should have_db_index :api_key_id
  
  # Validations
  ############################################################################
  should validate_presence_of :api_key
  should validate_presence_of :api_version
  should validate_presence_of :url
  should validate_presence_of :status  
  should validate_presence_of :ip  
  
end