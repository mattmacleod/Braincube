require File.dirname(__FILE__) + '/../test_helper'

class PageTest < ActiveSupport::TestCase
  
  # Metatests
  ############################################################################
  should_be_valid_with_factory

  # Model definition
  ############################################################################
  should belong_to :menu
  should belong_to :parent
  should belong_to :user
  should have_many :children
  should have_many :widgets
  should have_many :page_widgets
  
  should validate_presence_of :title
  should validate_presence_of :page_type
  should validate_presence_of :user
  should validate_presence_of :menu
  should validate_presence_of :sort_order

  should_have_braincube_versions
  should_have_braincube_comments
  should_have_braincube_tags
  
  should have_db_index([:url, :menu_id]).unique(true)
  should have_db_index([:parent_id, :menu_id, :starts_at, :ends_at, :enabled]).unique(false)
  
  
  # General tests
  ############################################################################
  
  context "Pages" do
    setup do
      @pages = [
                  @page1 = Factory(:root_page),
                  @page2 = Factory(:page, :title=>"c", :parent => @page1),
                  @page3 = Factory(:page, :title=>"b", :parent => @page1),
                  @page4 = Factory(:page, :title=>"d", :parent => @page3)
                 ]
    end
    
    should "have a tree root" do
      assert_equal Page.root, @page1
    end
    
    should "have the correct ancestor tree" do
      assert_equal [@page1, @page3, @page4], @page4.ancestors
    end
    
    should "be deleted when parents are deleted" do
      @page3.destroy
      assert_equal 0, Page.where(:title => "d").count
    end
    
    should "not be able to make self parent" do
      @page2.parent_id = @page2.id
      assert !@page2.save
    end
    
  end
  
  
end