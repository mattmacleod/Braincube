require File.dirname(__FILE__) + '/../test_helper'

class LockTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
  # Attributes and methods
  ############################################################################
  should belong_to :lockable
  should belong_to :user

  should have_db_index [:lockable_type, :lockable_id, :user_id]
  should have_db_index([:lockable_type, :lockable_id]).unique(true)
    
  # Validations
  ############################################################################
  should validate_presence_of :user
  should validate_presence_of :lockable
  should validate_presence_of :created_at
  should validate_presence_of :updated_at
  
  
  context "a lock on an item" do
    setup do
      @article = Factory(:article)
      @lock = Factory(:lock, :lockable => @article, :updated_at => Time::now)
    end
    should "not allow a second lock on the same item" do
      @lock2 = Factory.build(:lock, :lockable => @article)
      assert !@lock2.save
    end
    should "respond correctly to locked? method" do
      assert @article.locked?
    end
    context "with a updated_at time more than two minutes ago" do
      setup { @lock.update_attribute(:updated_at, 10.minutes.ago) }
      should "not be locked" do
        assert !@article.locked?
      end
    end
    context "when attempting to unlock" do
      should "succeed if the user is the same as the lock user" do
        assert @article.unlock!( @lock.user )
      end
      should "succeed if no user is specified" do
        assert @article.unlock!
      end
      should "fail if the wrong user is specified" do
        assert !(@article.unlock!(Factory(:user)))
      end
    end
  end
  
end
