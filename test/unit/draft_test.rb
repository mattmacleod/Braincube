require File.dirname(__FILE__) + '/../test_helper'

class DraftTest < ActiveSupport::TestCase
  
  # Metatests
  ############################################################################
  should_be_valid_with_factory


  # Model definition
  ############################################################################
  should belong_to :item
  should belong_to :user
  should validate_presence_of :item
  should validate_presence_of :user
  should validate_presence_of :item_data
  
  should have_db_index([:item_id, :item_type]).unique(true)
  
    
  # General tests
  ############################################################################
  
  context "a versioned item" do
    setup do
      @item = Factory( :article, :title => "Not a draft" )
    end
    
    should "be able to create drafts" do
      assert @item.save_draft( Factory(:user, :name => "Test user"), {"title" => "This is a draft"} )
    end
    
    context "when a draft is created" do
      setup do
        @draft = @item.save_draft( Factory(:user, :name => "Test user"), {"title" => "This is a draft"} )
      end
      
      should "not alter the content of the item" do
        assert_equal "Not a draft", @item.title
      end
      
      context "when the draft is loaded" do
        setup do
          @item.load_draft
        end
        should "update the item attributes to reflect the draft" do
          assert_equal "This is a draft", @item.title
        end
        should "not alter the item" do
          assert @item2 = Article.find( @item.id )
          assert_equal "Not a draft", @item2.title
        end
      end
    end
    
  end
   
  
end
