require File.dirname(__FILE__) + '/../../test_helper'

class Admin::AssetFoldersControllerTest < ActionController::TestCase
  
  
  # Test routes
  ###########################################################################
  
  should "route to correct asset folder pages" do
    assert_routing "/admin/asset_folders",                { :controller=>"admin/asset_folders", :action=>"index" }
    assert_routing "/admin/asset_folders/new",            { :controller=>"admin/asset_folders", :action=>"new" }
    assert_routing "/admin/asset_folders/1/edit",         { :controller=>"admin/asset_folders", :action=>"edit", :id=> "1" }
    assert_routing "/admin/asset_folders/1-root",         { :controller=>"admin/asset_folders", :action=>"index", :path=> "1-root" }
  end
  

  # Check lists
  ###########################################################################
  
  context "when logged in as an admin user with a root asset folder" do
    setup do
      @user = Factory(:admin_user)
      login_as @user
      @root_folder = Factory(:asset_folder, :name => "root", :parent => nil)
    end
    
    context "a get to :new" do
      setup { get :new }
      should render_template :new
      should respond_with :success
      should_not set_the_flash
      should "display the new asset folder form" do
        assert assigns(:asset_folder)
        assert assigns(:asset_folder).is_a? AssetFolder
        assert_select "input#asset_folder_name"
      end
    end
    
    context "a post to :create with invalid details" do
      setup { post :create, :asset_folder=>{:name=>""} }
      should_show_errors
      should render_template :new
      should_not set_the_flash
    end
    
    
    context "a post to :create with valid details" do
      setup { post :create, :asset_folder=>{
        :name => "test folder", :parent_id => @root_folder.id
        } 
      }
      should redirect_to "/admin/asset_folders/1-root/2-test_folder"
      should set_the_flash do /saved/i end
    end
    
    context "a DELETE to the root folder" do
      setup { delete :destroy, :id=>@root_folder.id }
      should respond_with :redirect
      should redirect_to "/admin/asset_folders"
      should set_the_flash do /failed/i end
    end
    
    context "a GET to the asset folder edit page" do
      setup { get :edit, :id=>@root_folder.id }
      should "respond with the asset folder editing form" do
        assert_equal @root_folder, assigns(:asset_folder)
      end
    end
     
    context "a GET to the root folder show page" do
      setup { get :show, :id=>@root_folder.id }
      should respond_with :redirect
      should redirect_to "/admin/asset_folders/1-root"
    end
    
    context "a GET to a nonexistent asset folder management page" do
      setup { get :index, :path=>"0-root"  }
      should respond_with :redirect
      should redirect_to "/admin/asset_folders/1-root"
    end   
    
    context "with subfolders" do
      setup do 
        @folder1 = Factory(:asset_folder, :parent => @root_folder, :name => "Test")
      end
      
      context "a GET to the asset folder browser page for the subfolder" do
        setup { get :index, :path => "1-root/#{@folder1.id}-test" }
        should "return no assets" do
          assert_equal [], assigns(:assets)
        end
        should "display the correct folder path" do
          assert_select "ul.asset_folder_list a.current"
        end
      end
      
      context "a DELETE to an asset folder page" do
        setup { delete :destroy, :id => @folder1.id }
        should respond_with :redirect
        should redirect_to "/admin/asset_folders/1-root"
        should set_the_flash do /deleted/i end
      end
      
      context "a GET to the new asset folder page" do
        setup { get :new }
        should "contain a select menu including the subfolder" do
          assert_select "select option", "-- Test"
        end
      end
      
      context "a POST to the asset folder update page with valid details" do
        setup { post :update, :id => @folder1.id, :asset_folder=>{
          :name => "test folder", :parent_id => @root_folder.id
          } 
        }
        should respond_with :redirect
        should set_the_flash do /saved/i end
      end

      context "a POST to the asset folder update page with invalid details" do
        setup { post :update, :id => @folder1.id, :asset_folder=>{:name=>""} }
        should respond_with :success
        should render_template :edit
        should_show_errors
      end
      
    end
    
    context "containing multiple assets," do
      setup do
        @assets = [ 
          @asset = Factory(:asset, :asset_folder => @root_folder, :title => "test"), 
          @asset2 = Factory(:asset, :asset_folder => @root_folder, :title => "other"),
          @asset3 = Factory(:asset, :asset_folder => Factory(:asset_folder), :title => "folder")
        ]
      end
      
      context "a GET to :index" do
        setup { get :index }
        should redirect_to "/admin/asset_folders/1-root"
      end
      
      context "a GET to the asset browser page" do
        setup { get :index, :path => "1-root" }
        should "return all assets in the specified folder" do
          assert_same_elements [@asset, @asset2], assigns(:assets)
        end
      end
      
      context "a GET to the asset browser page with a search string" do
        setup { get :index, :path => "1-root", :q => "other" }
        should "return matching assets" do
          assert_same_elements [@asset2], assigns(:assets)
        end
      end
      
      context "a GET to the asset browser page with a search string for an asset in another folder" do
        setup { get :index, :path => "1-root", :q => "folder" }
        should "not find assets in other folders" do
          assert_same_elements [], assigns(:assets)
        end
      end
      
      context "a GET to the asset browser page with a search string for an asset in another folder and the 'all folders' option selected" do
        setup { get :index, :path => "1-root", :q => "folder", :location => "all" }
        should "find assets in other folders" do
          assert_same_elements [@asset3], assigns(:assets)
        end
      end
      
      context "an xhr GET to the asset browser" do
        setup { xhr :get, :index, :path => "1-root" }
        should "return all assets in the specified folder" do
          assert_same_elements [@asset, @asset2], assigns(:assets)
        end
      end
      
      context "an xhr GET to the asset browser for a specific page" do
        setup { xhr :get, :index, :path => "1-root", :page => "2" }
        should "return no assets" do
          assert_same_elements [], assigns(:assets)
        end
      end
      
      context "an xhr GET to the asset browser with a query" do
        setup { xhr :get, :index, :path => "1-root", :q => "other" }
        should "return one asset" do
          assert_same_elements [@asset2], assigns(:assets)
        end
      end
      
      context "an xhr GET to the asset browser with a query matching another folder" do
        setup { xhr :get, :index, :path => "1-root", :q => "folder" }
        should "return one asset" do
          assert_same_elements [], assigns(:assets)
        end
      end
      
      context "an xhr GET to the asset browser with a query matching another folder and the 'all' location flah" do
        setup { xhr :get, :index, :path => "1-root", :q => "folder", :location => "all" }
        should "return one asset" do
          assert_same_elements [@asset3], assigns(:assets)
        end
      end
      
      context "a get to :attach" do
        setup { get :attach }
        should "return a list of assets in the selected folder" do
          assert_same_elements [@asset, @asset2], assigns(:assets)
        end
        should "generate a new asset" do
          assert assigns(:asset)
          assert assigns(:asset).is_a?( Asset )
        end
        should "generate a new URL upload request" do
          assert assigns(:url_upload)
          assert assigns(:url_upload).is_a?( UrlUpload )
        end
        should "generate a new Google upload request" do
          assert assigns(:google_url_upload)
          assert assigns(:google_url_upload).is_a?( UrlUpload )
        end
      end
      
      context "a post to :attach with valid asset details" do
        setup { post :attach, :asset=>{
          :title => "test asset", :asset_folder_id => @root_folder.id, 
          :asset => fixture_file_upload("files/images/test_image_small_rgb.jpg", "image/jpeg" )
          } 
        }
        should respond_with :redirect
      end
      
      context "a post to :attach with invalid asset details" do
        setup { post :attach, :asset=>{ :title => "" } }
        should respond_with :success
      end
      
      context "a post to :attach with valid URL upload details" do
        setup { post :attach, :url_upload => { :title => "test", :asset_folder_id => @root_folder.id, :url=>"http://test.host" } }
        should respond_with :redirect
      end
      
      context "a post to :attach with invalid URL upload details" do
        setup { post :attach, :url_upload=>{ :title => "" } }
        should respond_with :success
      end
      
      context "a post to :attach with valid URL upload details and a google flag" do
        setup { post :attach, {:google => 1, :url_upload => { :title => "test", :asset_folder_id => @root_folder.id, :url=>"http://test.host" }} }
        should respond_with :redirect
      end
      
      context "a post to :attach with invalid URL upload details and a google flag" do
        setup { post :attach, :google => 1, :url_upload=>{ :title => "" } }
        should respond_with :success
      end
      
      
    end
  end
  
  
end
