require File.dirname(__FILE__) + '/../test_helper'

class AssetFolderTest < ActiveSupport::TestCase
  
  # Metatests
  ############################################################################
  should_be_valid_with_factory


  # Model definition
  ############################################################################
  should belong_to :parent
  should have_many :children
  should have_many :assets
  
  should validate_presence_of :name
  
  should have_db_index :parent_id
  should have_db_index([:name, :parent_id]).unique(true)
  
  # General tests
  ############################################################################
  
  context "Asset folders" do
    setup do
      @folders = [
                  @folder1 = Factory(:asset_folder, :name=>"a", :parent => nil),
                  @folder2 = Factory(:asset_folder, :name=>"c", :parent => @folder1),
                  @folder3 = Factory(:asset_folder, :name=>"b", :parent => @folder1),
                  @folder4 = Factory(:asset_folder, :name=>"d", :parent => @folder3)
                 ]
      @folders.each(&:reload)
    end
    
    should "have a tree root" do
      assert_equal AssetFolder.root, @folder1
    end
    
    should "have the correct ancestor tree" do
      assert_equal [@folder1, @folder3, @folder4], @folder4.ancestors
    end
    
    should "have the correct parameter value" do
      assert_equal "#{@folder1.id}-a", @folder1.to_param
    end
  
    should "have the correct ancestor tree of parameter values" do
      assert_equal ["#{@folder1.id}-a", "#{@folder3.id}-b"], @folder3.path
    end
    
    should "validate uniqueness of name within parent" do
      @folder5 = Factory.build(:asset_folder, :name=>"c", :parent => @folder1)
      assert !@folder5.save
    end
    
    should "be listed in order of name within parent" do
      assert_equal [@folder3, @folder2], @folder1.children
    end
    
    should "be deleted when parents are deleted" do
      @folder3.destroy
      assert_equal 0, AssetFolder.where(:name => "d").count
    end
    
    should "not be able to make self parent" do
      @folder2.parent_id = @folder2.id
      assert !@folder2.save
    end
    
  end
  
end
