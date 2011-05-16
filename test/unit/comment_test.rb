require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < ActiveSupport::TestCase
  
  # Metatests
  ############################################################################
  should_be_valid_with_factory


  # Model definition
  ############################################################################
  should belong_to :item
  should belong_to :user
  should validate_presence_of :item
  should validate_presence_of :content
  
    
  # General tests
  ############################################################################
  
  context "Comments" do
    setup do
      # Keep item the same for ease
      @item = Factory(:article)
      @comments = [
        @c1 = Factory(:comment, :item=>@item, :created_at=>3.years.ago, :user => Factory(:user)),
        @c2 = Factory(:comment, :item=>@item, :created_at=>1.year.ago),
        @c3 = Factory(:comment, :item=>@item, :created_at=>2.years.ago)
        ]
    end
    should "be listed in order of date" do
      assert_equal [@c1, @c3, @c2], @item.comments
    end
    should "not be destroyed when associated user is destroyed" do
      @c1.user.destroy
      assert_equal 3, Comment.where(:item_id=>@item.id).count
    end
    should "be destroyed when linked item is destroyed" do
      @item.destroy
      assert_equal 0, Comment.where(:item_id=>@item.id).count
    end
    
    context "when reported" do
      setup { assert @c1.toggle!(:reported) }
      should "remain visible" do
        assert_includes @c1, Comment.visible.all
      end
      should "appear in reported comment list" do
        assert_includes @c1, Comment.reported.all
      end
      context "and approved" do
        setup { assert @c1.toggle!(:approved) }
        should "remain visible" do
          assert_includes @c1, Comment.visible.all
        end
        should "not appear in reported comment list" do
          assert !Comment.reported.all.include?(@c1)
        end
      end
      context "and hidden" do
        setup { assert @c1.toggle!(:hidden) }
        should "not be visible" do
          assert !Comment.visible.all.include?(@c1)
        end
        should "not appear in reported comment list" do
          assert !Comment.reported.all.include?(@c1)
        end
      end
    end
    context "when hidden" do
      setup { assert @c1.toggle!(:hidden) }
      should "not be visible" do
        assert !Comment.visible.all.include?(@c1)
      end
      should "not appear in reported comment list" do
        assert !Comment.reported.all.include?(@c1)
      end
    end
    
  end
  
  
end