require File.dirname(__FILE__) + '/../test_helper'

class TagTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
 
  # Relationships
  ############################################################################
  should have_many :taggings


  # General
  ############################################################################
  context "a group of tags" do
    setup do
      @tags = [
        @tag1 = Factory(:tag),
        @tag2 = Factory(:tag),
        @tag3 = Factory(:tag)
      ]
    end
    should "be found or created as required" do
      assert_equal(@tag1, Tag::find_or_create( @tag1.name ) )
      assert (@tag4 = Factory(:tag))
    end
    context "when attached to taggable items" do
      setup do
        @taggables = [
          @taggable1 = Factory(:article, :tag_list => "#{@tag1.name}, #{@tag2.name}"),
          @taggable2 = Factory(:article, :tag_list => "#{@tag2.name}")
        ]
      end
      should "produce correct list of popular tags" do
        # 2 most popular; 1 least popular; 3 shouldn't show
        assert_equal([@tag2, @tag1], Tag::popular.all)
      end
      context "when taggings changed" do
        setup do
          @taggable1.tag_list = "#{@tag2.name}, #{@tag3.name}"
          @taggable1.save!
        end
        should "maintain correct tagging" do
          assert_equal([@tag2, @tag3], Tag::popular.all)
        end
      end
    end
    
  end
  

end