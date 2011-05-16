require File.dirname(__FILE__) + '/../test_helper'

class AssetLinkTest < ActiveSupport::TestCase
  
  # Metatests
  ############################################################################
  should_be_valid_with_factory


  # Model definition
  ############################################################################
  should belong_to :item
  should belong_to :asset
  should validate_presence_of :item
  should validate_presence_of :asset
  should validate_presence_of :sort_order
  
    
  # General tests
  ############################################################################
  
  context "Asset links" do
    setup do
      # Keep item the same for ease
      @item = Factory(:article)
      @links = [
        @l1 = Factory(:asset_link, :item=>@item, :sort_order=>3),
        @l2 = Factory(:asset_link, :item=>@item, :sort_order=>1),
        @l3 = Factory(:asset_link, :item=>@item, :sort_order=>2)
        ]
    end
    should "be listed in order of order attribute" do
      assert_equal [@l2, @l3, @l1], @item.asset_links
    end
    should "be destroyed when associated asset is destroyed" do
      @l1.asset.destroy
      assert_equal 2, AssetLink.where(:item_id=>@item.id).count
    end
    should "be destroyed when linked item is destroyed" do
      @item.destroy
      assert_equal 0, AssetLink.where(:item_id=>@item.id).count
    end
  end
  
  
end
