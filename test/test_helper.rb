# Setup the test environment
##############################################################################
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")


# Load test helper
##############################################################################
require 'rails/test_help'


# Load Shoulda macros
##############################################################################
Dir[File.expand_path(File.dirname(__FILE__) + '/shoulda_macros/*.rb')].each {|file| require file }


# Fix weird routing issue
##############################################################################
Braincube::Application.routes.inspect

class ActiveSupport::TestCase
  fixtures :all
  
  
  # Add some general test helpers
  ############################################################################
  
  # Check for elements being included in collections
  def assert_includes(elem, array, message = nil)
    message = build_message message, '<?> is not found in <?>.', elem, array
    assert_block message do
      array.include? elem
    end
  end
  
  # Helper to massage XML into HTML so we can use test helpers on it
  def xml_document
    @xml_document ||= HTML::Document.new(@response.body, false, true)
  end
  
  # An addon to the assert_select helper to do the same to XML (using the
  # method mentioned above)
  def assert_xml_select(*args, &block)
    @html_document = xml_document
    assert_select(*args, &block)
  end
  
end
