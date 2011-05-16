require File.dirname(__FILE__) + '/../test_helper'

class AuthorTest < ActiveSupport::TestCase
  
  # Metatests
  ############################################################################
  should_be_valid_with_factory


  # Model definition
  ############################################################################
  should belong_to :user
  should belong_to :article
  should validate_presence_of :article
  should validate_presence_of :sort_order
  
    
  # General tests
  ############################################################################
  
  context "Authors" do
    setup do
      @article = Factory(:article)
      @user = Factory(:user)
      @authors = [
        @a1 = Factory(:author, :article => @article, :sort_order => 3),
        @a2 = Factory(:author, :article => @article, :sort_order => 1),
        @a3 = Factory(:author, :article => @article, :sort_order => 2)
        ]
    end
    should "not allow the same author to be assigned more than once to the same article" do
      @a4 = Factory.build(:author, :article => @a1.article, :user => @a1.user)
      assert !@a4.save
    end
    should "be listed in order of sort_order attribute" do
      assert_equal [@a2, @a3, @a1], @article.authors.all
    end
    should "be destroyed when associated user is destroyed" do
      @a1.user.destroy
      assert_equal 0, Author.where(:user_id => @a1.user.id).count
    end
    should "be destroyed when associated article is destroyed" do
      @a1.article.destroy
      assert_equal 0, Author.where(:article_id => @a1.id).count
    end
  end
  
  
end