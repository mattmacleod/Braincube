require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ArticlesControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct user pages" do
    
    # Main pages
    assert_routing "/admin/articles",              { :controller=>"admin/articles", :action=>"index" }
    assert_routing "/admin/articles/unsubmitted",  { :controller=>"admin/articles", :action=>"unsubmitted" }
    assert_routing "/admin/articles/editing",      { :controller=>"admin/articles", :action=>"editing" }
    assert_routing "/admin/articles/subediting",   { :controller=>"admin/articles", :action=>"subediting" }
    assert_routing "/admin/articles/publishing",   { :controller=>"admin/articles", :action=>"publishing" }
    assert_routing "/admin/articles/live",         { :controller=>"admin/articles", :action=>"live" }
    assert_routing "/admin/articles/inactive",     { :controller=>"admin/articles", :action=>"inactive" }
    assert_routing "/admin/articles/download",     { :controller=>"admin/articles", :action=>"download" }

    # Article pages
    assert_routing "/admin/articles/1",          { :controller=>"admin/articles", :action=>"show", :id=>"1" }
    assert_routing "/admin/articles/1.indtt",    { :controller=>"admin/articles", :action=>"show", :id=>"1", :format=>"indtt" }
    assert_routing "/admin/articles/1/edit",     { :controller=>"admin/articles", :action=>"edit", :id=>"1" }
    assert_routing "/admin/articles/1/print",    { :controller=>"admin/articles", :action=>"show", :id=>"1", :print => true }
    
    # Additional
    assert_routing "/admin/articles/download/test-edition",     { :controller=>"admin/articles", :action=>"download", :id=>"test-edition" }

  end
  
  
  # Tests for when not logged in
  ###########################################################################
  
  should_require_role :writer, :editor, :subeditor, :publisher, :admin


  context "with articles" do
    setup do
      @articles = [
        @unsubmitted = Factory(:article, :user => (@writer = Factory(:user, :role => "WRITER")), :status => Article::Status[:unsubmitted],  :updated_at => 9.days.ago ),
        @editing     = Factory(:article, :status => Article::Status[:editing],      :updated_at => 8.days.ago ),
        @subediting  = Factory(:article, :title => "Find me", :status => Article::Status[:subediting],   :updated_at => 7.days.ago, :review => true, :review_rating => 3 ),
        @publishing  = Factory(:article, :status => Article::Status[:published],    :updated_at => 6.days.ago, :starts_at => (Time::now + 1.year) ),
        @publishing2 = Factory(:article, :status => Article::Status[:ready],        :updated_at => 5.days.ago ),
        @live        = Factory(:article, :status => Article::Status[:published],    :updated_at => 4.days.ago ),
        @inactive    = Factory(:article, :status => Article::Status[:published],    :updated_at => 3.days.ago, :ends_at => 10.days.ago ),
        @deleted     = Factory(:article, :status => Article::Status[:removed],      :updated_at => 2.days.ago )
      ]
      @valid_article_details = {
        :title => "test",
        :user_id => User.first.id,
        :section_id => Section.first.id
      }
      @invalid_article_details = {
        :title => ""
      }
    end
    
    
    # User permission checks
    ##########################################################################
    
    context "when logged in as a writer" do
      setup do
        @user = @writer
        login_as @user
      end
      context "a GET to :index" do
        setup { get :index }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "only show user's articles" do
          assert_equal [@unsubmitted], assigns(:articles)
        end
      end
    end
    
    context "when logged in as a editor" do
      setup do
        @user = Factory(:user, :role=>"EDITOR")
        login_as @user
      end
      context "a GET to :editing" do
        setup { get :editing }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show the editing queue articles" do
          assert_same_elements [@editing], assigns(:articles)
        end
        should "show correct links" do
          assert_select "a.article_edit"
          assert_select "a.article_destroy"
        end
      end
    end
    
    context "when logged in as a subeditor" do
      setup do
        @user = Factory(:user, :role=>"SUBEDITOR")
        login_as @user
      end
      context "a GET to :subediting" do
        setup { get :subediting }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show the subediting queue articles" do
          assert_same_elements [@subediting], assigns(:articles)
        end
        should "show correct links" do
          assert_select "a.article_edit"
          assert_select "a.article_destroy"
        end
      end
    end
    
    context "when logged in as an admin user" do
      setup do
        @user = Factory(:admin_user)
        login_as @user
      end
      
      
      # General article queue checks
      ###########################################################################
      
      context "a GET to :index" do
        setup { get :index }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "include the most recently-updated articles" do
          assert_equal [@inactive, @live, @publishing2, @publishing, @subediting, @editing, @unsubmitted], assigns(:articles)
        end
        should "include review stars for reviews" do
          assert_select "span.review_rating" do
            assert_select "img", 3
          end
        end
      end
      
      context "ax xhr GET to :index with a query" do
        setup { xhr :get, :index, :q => "Find me" }
        should_not set_the_flash
        should render_template :list
        should respond_with :success
        should "include matching recently-updated articles" do
          assert_equal [@subediting], assigns(:articles)
        end
      end
      
      context "a GET to :unsubmitted" do
        setup { get :unsubmitted }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show the unsubmitted articles" do
          assert_same_elements [@unsubmitted], assigns(:articles)
        end
        should "include links to edit the unsubmitted articles" do
          assert_select "a", "Edit article"
          assert_select "a", "Obliterate article"
        end
      end
      
      
      context "a GET to :editing" do
        setup { get :editing }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show the articles in the editing queue" do
          assert_same_elements [@editing], assigns(:articles)
        end
        should "include links to edit the articles" do
          assert_select "a", "Edit article"
          assert_select "a", "Obliterate article"
        end
      end
      
      context "a GET to :subediting" do
        setup { get :subediting }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show the articles in the subbing queue" do
          assert_same_elements [@subediting], assigns(:articles)
        end
        should "include links to subedit the articles" do
          assert_select "a", "Edit article"
          assert_select "a", "Obliterate article"
          assert_select "a", "Show article"
          assert_select "a", "Print article"
          assert_select "a", "Download for InDesign"
        end
      end
      
      
      context "a GET to :publishing when one article is locked by another user" do
        setup do
          @publishing.lock!( Factory(:user) )
          get :publishing
        end
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show the articles in the publishing queue" do
          assert_same_elements [@publishing, @publishing2], assigns(:articles)
        end
        should "include links to manage publishing of the articles" do
          assert_select "a", "Edit article"
          assert_select "a", "Obliterate article"
          assert_select "a", "Show article"
          assert_select "a", "Print article"
          assert_select "a", "Download for InDesign"
        end
        should "show one of the articles as locked" do
          assert_select "a.locked", 1
        end
      end
      
      context "a GET to :live" do
        setup { get :live }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show the live articles" do
          assert_same_elements [@live], assigns(:articles)
        end
        should "include links to edit the live articles" do
          assert_select "a", "Edit article"
          assert_select "a", "Unpublish article"
          assert_select "a", "Obliterate article"
          assert_select "a", "Show article"
          assert_select "a", "Print article"
          assert_select "a", "Download for InDesign"
        end
      end
      
      context "a GET to :inactive" do
        setup { get :inactive }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show the inactive (unpublished) articles" do
          assert_same_elements [@inactive], assigns(:articles)
        end
        should "include links to edit the inactive articles" do
          assert_select "a", "Edit article"
          assert_select "a", "Obliterate article"
          assert_select "a", "Show article"
          assert_select "a", "Print article"
          assert_select "a", "Download for InDesign"
        end
      end
      
      context "a GET to :download with no issue set" do
        setup { get :download }
        should_not set_the_flash
        should render_template :index
        should respond_with :success
        should "show all downloadable articles" do
          assert_same_elements [@inactive, @live, @publishing2, @publishing], assigns(:articles)
        end
        should "include links to edit the articles" do
          assert_select "a", "Edit article"
          assert_select "a", "Obliterate article"
          assert_select "a", "Show article"
          assert_select "a", "Print article"
          assert_select "a", "Download for InDesign"
        end
      end
      

      # Showing articles (do it all as admin user)
      ###########################################################################

      # Check loading a show page
      context "a GET to :show for an unsubmitted article" do
        setup { get :show, { :id => @unsubmitted.to_param } }
        should_not set_the_flash
        should render_template :show
        should respond_with :success
        should "show the requested article" do
          assert_equal @unsubmitted, assigns(:article)
        end
        should "display the article title" do
          assert_select "h1", @unsubmitted.title
        end
      end
      
      context "a GET to :show an article in indesign format" do
        setup { get :show, { :id => @unsubmitted.to_param, :format => :indtt } }
        should_not set_the_flash
        should render_template :show
        should respond_with :success
      end
      
      
      
      # Creating articles (do it all as admin user)
      ###########################################################################
      
      # Loading the page
      context "a GET to :new" do
        setup { get :new }
        should_not set_the_flash
        should render_template :new
        should respond_with :success
        should "create a new article" do
          assert assigns(:article)
        end
        should "display the article editing form" do
          assert_select "input#article_title"
          assert_select "textarea#article_content"
        end
      end
      
      # Check that we can create articles
      context "a POST to :create with valid article details" do
        setup { post :create, :article => @valid_article_details }
        should set_the_flash do /created/i end
        should respond_with :redirect
        should redirect_to "/admin/articles"
      end
      
      # Check that we can create articles
      context "a POST to :create with valid article details and the stage_complete parameter" do
        setup { post :create, :article => @valid_article_details, :stage_complete => true }
        should set_the_flash do /submitted/i end
        should respond_with :redirect
        should redirect_to "/admin/articles"
        should "mark the article as submitted" do
          assert_equal :editing, assigns(:article).queue
        end
      end
      
      context "a POST to :create with invalid article details" do
        setup { post :create, :article => @invalid_article_details }
        should_not set_the_flash
        should respond_with :success
        should render_template :new
      end
      
      
      
      # Locks
      ###########################################################################
      context "an xhr GET to :check_lock for an article locked by the current user" do
        setup { @lock = @unsubmitted.lock!(@user); xhr :get, :check_lock, { :id => @unsubmitted.to_param } }
        should render_template :lock_info
        should "not unlock article" do assert assigns(:article).locked? end
      end
      context "an xhr GET to :check_lock for an article locked by another" do
        setup { @lock = @unsubmitted.lock!(@user2 = Factory(:user)); xhr :get, :check_lock, { :id => @unsubmitted.to_param } }
        should render_template :lock_info
        should "not unlock article" do assert assigns(:article).locked? end
        should "not leave lock with other user" do assert_equal @user2, assigns(:article).lock.user end
      end
      context "an xhr GET to :check_lock for an unlocked article" do
        setup { xhr :get, :check_lock, { :id => @unsubmitted.to_param } }
        should render_template :lock_info
        should "not unlock article" do assert assigns(:article).locked? end
      end
      
      
      # Editing articles (do it all as admin user)
      ###########################################################################
      
      # Check all of the different queues for editing
      context "a GET to :edit for an unsubmitted article" do
        setup { get :edit, { :id => @unsubmitted.to_param } }
        should_not set_the_flash
        should render_template :edit
        should respond_with :success
        should "load the requested article" do
          assert_equal @unsubmitted, assigns(:article)
        end
        should "lock the requested article" do
          assert assigns(:article).locked?
        end
        should "display the article editing form" do
          assert_select "input#article_title"
          assert_select "textarea#article_content"
        end
        should "highlight the unsubmitted subnavigation tab" do
          assert_select "#sub_navigation li.active a", "Unsubmitted"
        end
      end
      
      context "a GET to :edit for an unsubmitted article with a draft" do
        setup do
           @unsubmitted.save_draft( @user, {:title => "This is a draft"})
           get :edit, { :id => @unsubmitted.to_param }
        end
        should_not set_the_flash
        should render_template :edit
        should "load the requested article" do
          assert_equal @unsubmitted, assigns(:article)
        end
        should "display the draft information" do
          assert_select "input#article_title[value=This is a draft]"
        end
      end
      
      context "a POST to :revert_draft for an unsubmitted article with a draft" do
        setup do
           @unsubmitted.save_draft( @user, {:title => "This is a draft"})
           post :revert_draft, { :id => @unsubmitted.to_param }
        end
        should set_the_flash do /reverted/i end
        should respond_with :redirect
        should "load the requested article" do
          assert_equal @unsubmitted, assigns(:article)
        end
        should "not display the draft information" do
          assert_select "input#article_title[value=This is a draft]", 0
        end
      end
      
      context "a GET to :edit for an unsubmitted article locked by the active user" do
        setup { @lock = @unsubmitted.lock!(@user); get :edit, { :id => @unsubmitted.to_param } }
        should_not set_the_flash
        should render_template :edit
      end
      context "a GET to :edit for an unsubmitted article locked by another user" do
        setup { @lock = @unsubmitted.lock!(Factory(:user)); get :edit, { :id => @unsubmitted.to_param } }
        should_not set_the_flash
        should render_template :edit
      end
      
      context "a GET to :edit for an editing article" do
        setup { get :edit, { :id => @editing.to_param } }
        should_not set_the_flash
        should render_template :edit
        should respond_with :success
        should "load the requested article" do
          assert_equal @editing, assigns(:article)
        end
        should "display the article editing form" do
          assert_select "input#article_title"
          assert_select "textarea#article_content"
        end
        should "highlight the editing subnavigation tab" do
          assert_select "#sub_navigation li.active a", "Editing"
        end
      end
        
      context "a GET to :edit for an subediting article" do
        setup { get :edit, { :id => @subediting.to_param } }
        should_not set_the_flash
        should render_template :edit
        should respond_with :success
        should "load the requested article" do
          assert_equal @subediting, assigns(:article)
        end
        should "display the article editing form" do
          assert_select "input#article_title"
          assert_select "textarea#article_content"
        end
        should "highlight the subediting subnavigation tab" do
          assert_select "#sub_navigation li.active a", "Subediting"
        end
      end
      
      context "a GET to :edit for an publishing article" do
        setup { get :edit, { :id => @publishing.to_param } }
        should_not set_the_flash
        should render_template :edit
        should respond_with :success
        should "load the requested article" do
          assert_equal @publishing, assigns(:article)
        end
        should "display the article editing form" do
          assert_select "input#article_title"
          assert_select "textarea#article_content"
        end
        should "highlight the publishing subnavigation tab" do
          assert_select "#sub_navigation li.active a", "Publishing"
        end
      end
      
      context "a GET to :edit for an live article" do
        setup { get :edit, { :id => @live.to_param } }
        should_not set_the_flash
        should render_template :edit
        should respond_with :success
        should "load the requested article" do
          assert_equal @live, assigns(:article)
        end
        should "display the article editing form" do
          assert_select "input#article_title"
          assert_select "textarea#article_content"
        end
        should "highlight the live subnavigation tab" do
          assert_select "#sub_navigation li.active a", "Live"
        end
      end
      
      context "a GET to :edit for an inactive article" do
        setup { get :edit, { :id => @inactive.to_param } }
        should_not set_the_flash
        should render_template :edit
        should respond_with :success
        should "load the requested article" do
          assert_equal @inactive, assigns(:article)
        end
        should "display the article editing form" do
          assert_select "input#article_title"
          assert_select "textarea#article_content"
        end
        should "highlight the inactive subnavigation tab" do
          assert_select "#sub_navigation li.active a", "Inactive"
        end
      end
      
      context "a GET to :edit for a removed article" do
        setup { get :edit, { :id => @deleted.to_param } }
        should set_the_flash do /edited/i end
        should redirect_to "/admin/articles"
      end
      
      
      # Check posting an edit - valid and invalid
      context "a PUT to :update for an unsubmitted article with valid details" do
        setup { put :update, { :id => @unsubmitted.to_param, :article => @valid_article_details } }
        should set_the_flash do /saved/i end
        should redirect_to "/admin/articles/unsubmitted"
      end
      
      context "a PUT to :update for an unsubmitted article with valid details with save_draft set" do
        setup { put :update, { :id => @unsubmitted.to_param, :article => @valid_article_details, :commit => "Save draft" } }
        should set_the_flash do /saved as a draft/i end
        should redirect_to "/admin/articles/unsubmitted"
      end
      
      # Check posting an edit - valid and invalid
      context "an XHR PUT to :update for a locked, unsubmitted article with valid details" do
        setup { @unsubmitted.lock!( @user ); xhr :put, :update, { :id => @unsubmitted.to_param, :article => @valid_article_details } }
        should_not set_the_flash
        should "not unlock article" do
          assert assigns(:article).locked?
        end
      end

      context "an XHR PUT to :update for a locked, unsubmitted article with valid details with save_draft set" do
        setup { @unsubmitted.lock!( @user ); xhr :put, :update, { :id => @unsubmitted.to_param, :article => @valid_article_details, :commit => "Save draft" } }
        should_not set_the_flash
        should "not unlock article" do
          assert assigns(:article).locked?
        end
        should "save a draft" do
          assert assigns(:article).has_draft?
        end
      end
      
      context "a PUT to :update for an unsubmitted article with invalid details" do
        setup { put :update, { :id => @unsubmitted.to_param, :article => @invalid_article_details } }
        should_not set_the_flash
        should render_template :edit
        should respond_with :success
      end
      
      
      # Check the editing process
      context "a DELETE to :destroy for an unsubmitted article" do
        setup { delete :destroy, { :id => @unsubmitted.to_param } }
        should set_the_flash do /obliterated/i end
        should redirect_to "/admin/articles"
        should "update the status of the article to be obliterated" do
          assert_equal Article::Status[:removed], assigns(:article).status
        end
      end
      
      context "a PUT to :update for an unsubmitted article with complete checked" do
        setup { put :update, { :id => @unsubmitted.to_param, :article => @valid_article_details, :stage_complete=>true } }
        should set_the_flash do /saved/i end
        should redirect_to "/admin/articles/editing"
        should "update the status of the article to the editing stage" do
          assert_equal :editing, assigns(:article).queue
        end
      end
      
      context "a PUT to :update for an unsubmitted article with publish_now checked" do
        setup { put :update, { :id => @unsubmitted.to_param, :article => @valid_article_details, :publish_now => true } }
        should set_the_flash do /saved/i end
        should redirect_to "/admin/articles/live"
        should "set article to live state" do
          assert_equal :live, assigns(:article).queue
        end
      end
      
      context "a PUT to :update for an editing article with complete checked" do
        setup { put :update, { :id => @editing.to_param, :article => @valid_article_details, :stage_complete=>true } }
        should set_the_flash do /saved/i end
        should redirect_to "/admin/articles/subediting"
        should "update the status of the article to the subbing stage" do
          assert_equal :subediting, assigns(:article).queue
        end
      end

      context "a PUT to :update for an subbing article with complete checked" do
        setup { put :update, { :id => @subediting.to_param, :article => @valid_article_details, :stage_complete=>true } }
        should set_the_flash do /saved/i end
        should redirect_to "/admin/articles/publishing"
        should "update the status of the article to the publishing stage" do
          assert_equal :publishing, assigns(:article).queue
        end
      end
      
      context "a PUT to :update for an publishing article with complete checked" do
        setup { put :update, { :id => @publishing2.to_param, :article => @valid_article_details, :stage_complete=>true } }
        should set_the_flash do /saved/i end
        should redirect_to "/admin/articles/live"
        should "update the status of the article to the live state" do
          assert_equal :live, assigns(:article).queue
        end
      end
      
      context "a POST to :unpublish for an live article" do
        setup { post :unpublish, { :id => @live.to_param } }
        should set_the_flash do /unpublished/i end
        should redirect_to "/admin/articles/publishing"
        should "update the status of the article to the ready state" do
          assert_equal :publishing, assigns(:article).queue
        end
      end
      
      
    end    
    
  end
  
  
end