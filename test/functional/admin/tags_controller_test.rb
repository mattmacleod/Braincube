require File.dirname(__FILE__) + '/../../test_helper'

class Admin::TagsControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct tag pages" do
    assert_routing "/admin/tags",                { :controller=>"admin/tags", :action=>"index" }
    assert_routing "/admin/tags/1",              { :controller=>"admin/tags", :action=>"show", :id => "1" }
  end
  
  
  # Tests for when not logged in
  ###########################################################################
  
  should_require_role :admin

  # Check lists
  ###########################################################################
  
  context "when logged in as an admin user" do
    setup do
      @user = Factory(:admin_user)
      login_as @user
    end
    
    context "a get to :new" do
      setup { get :new }
      should respond_with :redirect
      should redirect_to "/admin/tags"
    end
    
    context "a post to :create" do
      setup { post :create }
      should respond_with :redirect
      should redirect_to "/admin/tags"
    end

    context "with tags" do
      setup do
        @tags = [
          @tag1 = Factory(:tag, :name => "tag b"),
          @tag2 = Factory(:tag, :name => "tag a")
        ]
        @items = [
          @article = Factory(:article, :tag_list => "tag b"),
          @event = Factory(:event, :tag_list => "tag b"),
          @venue = Factory(:venue, :tag_list => "tag a")
        ]
      end
      
      context "a GET to :index" do
        setup { get :index }
        should "return all tags" do
          assert_same_elements @tags, assigns(:tags)
        end
      end

      context "an XHR GET to :index" do
        setup { xhr :get, :index }
        should "return all tags" do
          assert_same_elements @tags, assigns(:tags)
        end
        should render_template "list"
        should_not render_template "index"
      end

      context "a JSON GET to :index" do
        setup { get :index, :format => :json }
        should "return all tags" do
          assert_same_elements @tags, assigns(:tags)
        end
        should_not render_template "list"
        should_not render_template "index"
      end

      context "an XHR GET to :index with a query" do
        setup { xhr :get, :index, :q => "tag b" }
        should "return only tags matching the query" do
          assert_same_elements [@tag1], assigns(:tags)
        end
        should render_template "list"
        should_not render_template "index"
      end
          
      context "a JSON GET to :index with a query" do
        setup { get :index, :q => "tag b", :format => :json }
        should "return only tags matching the query" do
          assert_same_elements [@tag1], assigns(:tags)
        end
        should_not render_template "index"
        should_not render_template "list"
        should respond_with_content_type :json
      end
        
      context "a GET to the tag edit page" do
        setup { get :edit, :id => @tag1.id }
        should respond_with :redirect
        should redirect_to "/admin/tags"
      end
       
      context "a GET to the tag show page" do
        setup { get :show, :id => @tag1.id }
        should "respond with the tag information page" do
          assert_equal @tag1, assigns(:tag)
        end
        should "show the tag title" do
          assert_select "h1", "tag b"
        end
        should "show a list of items tagged with the tag" do
          assert_select "table.list" do
            assert_select "tbody tr", 2
          end
        end
      end

      context "a GET to a nonexistent tag page" do
        setup { get :show, :id=>0 }
        should respond_with 404
      end
      
      context "a POST to the tag update page" do
        setup { post :update, { :id => @tag1.id } }
        should respond_with :redirect
        should redirect_to "/admin/tags"
        should_not set_the_flash
      end
       
    end
    
  end
  
  
end
