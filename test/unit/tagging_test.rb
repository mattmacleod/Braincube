require File.dirname(__FILE__) + '/../test_helper'

class TaggingTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
 
  # Relationships
  ############################################################################
  should belong_to :taggable
  should belong_to :tag

end