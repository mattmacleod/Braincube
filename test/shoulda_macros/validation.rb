class ActiveSupport::TestCase

  def self.should_validate_email(attribute)
    should_not allow_value("notanemail").for(attribute)
    should_not allow_value("not@example").for(attribute)
    should_not allow_value("@example.com").for(attribute)
    
    should allow_value("test@example.com").for(attribute)
    should allow_value("text@example.co.uk").for(attribute)
    should allow_value("test@example.tv").for(attribute)
    should allow_value("!#\$%&'*+-/=?^_\`\{|\}~@example.com").for(attribute)
  end
  
  def self.should_show_errors(count=nil)
    should "display error notification" do
      assert_select "div.errors" do |elements|
        assert_select "h2"
        assert_select "ul", 1 do |items| 
          count.blank? ? assert_select("li") : assert_select("li", count)
        end
      end
    end
  end
  
end