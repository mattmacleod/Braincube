require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory
  
 
  # Attributes and methods
  ############################################################################
  should belong_to :section
  should belong_to :publication
  should belong_to :user
  should have_many :authors
  should have_many :authoring_users
  should have_many :reviewed_events
  should have_many :performances
  should have_and_belong_to_many :events
  should have_and_belong_to_many :venues
  
  # Custom bits
  should_have_braincube_tags
  should_have_braincube_comments
  should_have_braincube_assets
  should_have_braincube_lock
  should_have_braincube_properties
  should_have_braincube_url :url, :generated_from => :title
  should_have_braincube_versions
  
  # Attribute protection tests
  should_not allow_mass_assignment_of :status
  should_not allow_mass_assignment_of :word_count
  should_not allow_mass_assignment_of :user_id
  should_not allow_mass_assignment_of :cached_authors
  should_not allow_mass_assignment_of :cached_tags
  should_not allow_mass_assignment_of :created_at
  should_not allow_mass_assignment_of :updated_at
  should allow_mass_assignment_of :section
  
  # Indexes
  should have_db_index [:status, :starts_at, :ends_at, :print_only, :featured]
  should have_db_index [:review, :review_rating]
  should have_db_index :url


  # Validations
  ############################################################################
  should validate_presence_of :title
  should validate_presence_of :status
  should validate_presence_of :template
  should validate_presence_of(:article_type).with_message("must be specified")
  should validate_presence_of(:section_id).with_message("must be specified")
  should validate_presence_of :user


  # Cache updates
  ############################################################################
  context "a new Article" do
    
    setup do 
      @article = Factory(:article)
    end
    
    should "not appear in the live article list" do
      assert !Article.live.all.include?(@article)
    end
    
    should "generate the correct parameter value" do
      assert_equal "1-test_article", @article.to_param
    end
    
    # Check handling of authors
    context "with Authors" do
      
      setup do
        @user1 = Factory(:user, :name => "User 2", :role => "WRITER")
        @user2 = Factory(:user, :name => "User 1", :role => "WRITER")
        @article.writer_string = "User 2, User 1"
        @article.save!
      end
    
      should "have correct cached authors" do
        assert_equal "User 2 and User 1", @article.cached_authors
      end
      
      context "when an additional author is added and exists as a user" do
        setup do
          @new_user = Factory(:user, :name => "Test author user")
          @article.writer_string = "User 1, User 2, Test author user"
          @article.save
          @article.reload
        end
        should "have correct cached authors" do
          assert_equal "User 1, User 2, and Test author user", @article.cached_authors
        end 
      end
      
      context "when an additional author is added and does not exist as a user" do
        setup do
          @article.writer_string = "User 1, User 2, Another uncreated user"
          @article.save
          @article.reload
        end
        should "have correct cached authors" do
          assert_equal "User 1, User 2, and Another uncreated user", @article.cached_authors
        end 
      end
      
    end
    
    
    context "when associated events are set" do
      setup do
        @events = [ Factory(:event), Factory(:event) ]
        @article.associated_event_ids = @events.map(&:id).join(",")
        @article.save!
      end
      should "attach requested events" do
        assert_same_elements @events, @article.events
      end
    end
 
    context "when associated venues are set" do
      setup do
        @venues = [ Factory(:venue), Factory(:venue) ]
        @article.associated_venue_ids = @venues.map(&:id).join(",")
        @article.save!
      end
      should "attach requested venues" do
        assert_same_elements @venues, @article.venues
      end
    end   
    
  end

  # Test general article seasrches etc
  ############################################################################
  context "a series of Articles" do
    setup do
      @articles = [
        @unsubmitted = Factory(:article, :status => Article::Status[:unsubmitted],  :updated_at => 9.days.ago ),
        @editing     = Factory(:article, :status => Article::Status[:editing],      :updated_at => 8.days.ago ),
        @subediting  = Factory(:article, :status => Article::Status[:subediting],   :updated_at => 7.days.ago ),
        @publishing  = Factory(:article, :status => Article::Status[:published],    :updated_at => 6.days.ago, :starts_at => (Time::now + 1.year)),
        @publishing2 = Factory(:article, :status => Article::Status[:ready],        :updated_at => 5.days.ago ),
        @live        = Factory(:article, :status => Article::Status[:published],    :updated_at => 4.days.ago, :starts_at => 1.day.ago ),
        @inactive    = Factory(:article, :status => Article::Status[:published],    :starts_at => 1.day.ago, :ends_at => 3.days.ago,  :updated_at => 3.days.ago ),
        @deleted     = Factory(:article, :status => Article::Status[:removed],      :updated_at => 2.days.ago )
      ]
    end
  
    should "be correctly found by calls to #recently_updated" do
      assert_equal 4, Article::recently_updated(4).length
      assert_same_elements [@inactive, @live, @publishing2, @publishing], Article::recently_updated(4).all
      assert_same_elements [@inactive], Article::recently_updated(1).all
    end
    
    should "be in the correct queues" do
      expected = [
        :unsubmitted, :editing, :subediting, :publishing, :publishing, :live, 
        :inactive, nil
      ]
      assert_equal(expected, @articles.map(&:queue))
      assert_equal(Article::unsubmitted.all,  [@unsubmitted])
      assert_equal(Article::editing.all,      [@editing])
      assert_equal(Article::subediting.all,   [@subediting])
      assert_equal(Article::ready.all,        [@publishing2, @publishing])
      assert_equal(Article::inactive.all,     [@inactive])
      assert_equal(Article::downloadable.all, [@inactive, @live, @publishing2, @publishing])
    end
  end
  
  
  # TODO: check word count, events, abstract etc.
  ArticleAbstract = "This is the article abstract"
  ArticleContent = "This is the content of the article"
  ArticleHTMLContent = "This <strong>is</strong> the <p>HTML <em>content</em> of the</p> article"
  ArticleStandfirst = "This is the standfirst of the article"
  
  context "an Article with content" do
    
    setup do
      @article = Factory(:article, :content => ArticleContent)
    end
    
    should "use the body as the article abstract" do
      assert_equal ArticleContent, @article.get_abstract
    end
    
    context "and a standfirst" do
      setup { @article.update_attribute(:standfirst, ArticleStandfirst) }
      should "use the standfirst as the abstract" do
        assert_equal ArticleStandfirst, @article.get_abstract
      end
      context "and an abstract" do
        setup { @article.update_attribute(:abstract, ArticleAbstract) }
        should "use the specified abstract" do
          assert_equal ArticleAbstract, @article.get_abstract
        end
      end
    end
    
    context "and an abstract but no standfirst" do
      setup { @article.update_attribute(:abstract, ArticleAbstract) }
      should "use the specified abstract" do
        assert_equal ArticleAbstract, @article.get_abstract
      end
    end
    
    should "have the correct word count" do
      assert_equal 7, @article.word_count
    end
  end
  
  context "an article with HTML content" do
    setup { @article = Factory(:article, :content => ArticleHTMLContent) }
    should "strip out the HTML and provide the correct word count" do
      assert_equal 8, @article.word_count
    end
  end
  
  # Check the the correct things happen in every state
  ############################################################################
  
  context "an article in the unsubmited queue" do
    setup do
      @article = Factory(:article, :status => Article::Status[:unsubmitted] )
    end
    should "have a queue status of :unsubmitted" do
      assert_equal :unsubmitted, @article.queue
    end
    should "not be live" do
      assert !@article.live?
    end
    context "when calling stage_complete!" do
      setup { @article.stage_complete! && @article.reload }
      should "move to editing queue" do
        assert_equal :editing, @article.queue
      end
    end
    
    # Some additional bits that we don't need to repeat
    context "when calling publish_now!" do
      context "with no start date" do
        setup { @article.publish_now! && @article.reload }
        should "move to live queue" do
          assert_equal :live, @article.queue
          assert @article.live?
        end
      end
      context "with a start date in the future" do
        setup do
          @article.update_attribute(:starts_at, 1.year.since)
          @article.publish_now!
          @article.reload
        end
        should "move to publishing queue" do
          assert_equal :publishing, @article.queue
          assert !@article.live?
        end
      end
    end
    
  end
  
  context "an article in the editing queue" do
    setup do
      @article = Factory(:article, :status => Article::Status[:editing] )
    end
    should "have a queue status of :editing" do
      assert_equal :editing, @article.queue
    end
    should "not be live" do
      assert !@article.live?
    end
    context "when calling stage_complete!" do
      setup { @article.stage_complete! && @article.reload }
      should "move to subbing queue" do
        assert_equal :subediting, @article.queue
      end
    end
  end
  
  context "an article in the subediting queue" do
    setup do
      @article = Factory(:article, :status => Article::Status[:subediting] )
    end
    should "have a queue status of :subediting" do
      assert_equal :subediting, @article.queue
    end
    should "not be live" do
      assert !@article.live?
    end
    context "when calling stage_complete!" do
      setup { @article.stage_complete! && @article.reload }
      should "move to publishing queue" do
        assert_equal :publishing, @article.queue
      end
    end
  end
  
  context "an article in the publishing queue" do
    setup do
      @article = Factory(:article, :status => Article::Status[:ready] )
    end
    should "have a queue status of :publishing" do
      assert_equal :publishing, @article.queue
    end
    should "not be live" do
      assert !@article.live?
    end
    context "when calling stage_complete!" do
      setup { @article.stage_complete! && @article.reload }
      should "move to live queue" do
        assert_equal :live, @article.queue
      end
    end
  end
  
  context "an article in the live queue" do
    setup do
      @article = Factory(:article, :status => Article::Status[:published], :starts_at => 1.day.ago)
    end
    should "have a queue status of :live" do
      assert_equal :live, @article.queue
    end
    should "be live" do
      assert @article.live?
    end
     context "when calling stage_complete!" do
        setup { @article.stage_complete! && @article.reload }
        should "remain in the live queue" do
          assert_equal :live, @article.queue
        end
      end
  end
  
  context "an article in the inactive queue" do
    setup do
      @article = Factory(:article, :status => Article::Status[:published], :starts_at => 4.days.ago, :ends_at => 3.days.ago )
    end
    should "have a queue status of :inactive" do
      assert_equal :inactive, @article.queue
    end
    should "not be live" do
      assert !@article.live?
    end
  end
  
  context "a deleted article" do
    setup do
      @article = Factory(:article, :status => Article::Status[:removed] )
    end
    should "not be in a queue" do
      assert_nil @article.queue
    end
    should "not be live" do
      assert !@article.live?
    end
  end
  
  # Misc
  ############################################################################

  context "an imported article" do
    setup do
      @article = Factory(:article, :status => Article::Status[:ready], :starts_at => nil)
    end
    should "allow empty start date if draft" do
      assert_equal @article.starts_at, nil
    end
    should "set the start date if published" do
      @article.status = Article::Status[:published]
      @article.save
      assert_in_delta Time.now, @article.starts_at, 5
    end
  end
end
