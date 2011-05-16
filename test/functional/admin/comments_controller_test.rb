require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CommentsControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct comment admin pages" do
    assert_routing "/admin/comments",             { :controller=>"admin/comments", :action=>"index" }
    assert_routing "/admin/comments/1",           { :controller=>"admin/comments", :action=>"show", :id => "1" }
  end
  

  # Check lists
  ###########################################################################
  
  context "when logged in as an admin user" do
    setup do
      @user = Factory(:admin_user)
      login_as @user
    end
        
    context "with multiple comments" do
      setup do
        @comments = [ 
          @comment_1 = Factory(:comment, :created_at => 1.days.ago, :name => "Find this name"), 
          @comment_2 = Factory(:comment, :created_at => 10.days.ago, :email => "findthisemail@example.com") 
        ]
      end
      
      context "a DELETE to a comment" do
        setup { delete :destroy, :id => @comment_1.id }
        should respond_with :redirect
        should redirect_to "/admin/comments"
        should set_the_flash do /deleted/i end
      end
      
      context "a GET to the comment edit page" do
        setup { get :edit, :id => @comment_1.id }
        should "respond with the comment editing form" do
          assert_equal @comment_1, assigns(:comment)
          assert_select "#comment_name"
        end
      end
       
      context "a GET to the comment show page" do
        setup { get :show, :id => @comment_1.id }
        should respond_with :redirect
      end
      
      context "a GET to a nonexistent comment management page" do
        setup { get :edit, :id=>0 }
        should respond_with 404
      end
      
      context "a GET to a new comment page" do
        setup { get :new }
        should respond_with 404
      end
      
      context "a POST to the comment creation page" do
        setup { post :create }
        should respond_with 404
      end
      
      context "a GET to :index" do
        setup { get :index }
        should respond_with :success
        should "return all comments" do
          assert_same_elements @comments, assigns(:comments)
        end
      end
      
      context "an XHR GET to :index" do
        setup { xhr :get, :index }
        should respond_with :success
        should render_template :list
        should_not render_template "index"
        should "return all comments" do
          assert_same_elements @comments, assigns(:comments)
        end
      end
      
      context "an XHR GET to :index with a query" do
        setup { xhr :get, :index, { :q => "find this name"} }
        should "return one comment" do
          assert_equal [@comment_1], assigns(:comments)
        end
        should render_template "list"
        should_not render_template "index"
      end
      
      context "a POST to the comment approval page" do
        setup { post :approve, {:id=>@comment_1.id} }
        should respond_with :redirect
        should redirect_to "/admin/comments"
        should set_the_flash do /approved/i end
      end      
       
       context "a POST to the comment update page with valid details" do
         setup { post :update, {:id=>@comment_1.id, :comment => { :name => "Test" }} }
         should respond_with :redirect
         should redirect_to "/admin/comments"
         should set_the_flash do /saved/i end
       end
       
       context "a POST to the comment update page with invalid details" do
         setup { post :update, {:id=>@comment_1.id, :comment => { :name => "" }} }
         should respond_with :success
         should_show_errors
       end
       
      context "an XHR POST to the comment approval page" do
       setup { xhr :post, :approve, {:id=>@comment_1.id} }
       should respond_with :success
      end

    end
    
  end
  
  
end
