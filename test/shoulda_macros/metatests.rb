class ActiveSupport::TestCase
  
  # Additional test class helpers
  ############################################################################
  
  class << self
    
    def should_be_valid_with_factory
      klass = self.name.gsub(/Test$/, '').underscore.to_sym
      should "be valid with factory" do
        assert_valid Factory.build(klass)
      end
    end
    
  end
  
end