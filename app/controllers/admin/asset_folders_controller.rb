class Admin::AssetFoldersController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :new, :create, :edit, :destroy, :update, :browse], :roles => [:admin, :publisher, :subeditor] }
  )
  
  before_filter :load_folder
  
  def index
    if( params[:path].to_s.split("/") == @current_folder.path )
      @assets = (params[:location] == "all") ? Asset.where("asset_folder_id > 0") : @current_folder.assets
      @assets = @assets.where(["assets.title LIKE ?", "%#{params[:q]}%"]) if params[:q]
      @assets = @assets.paginate( :page => params[:page], :per_page => Braincube::Config::AdminAssetPaginationLimit )
      if request.xhr?
        render(:partial => "folder", :locals => {:assets => @assets})
        return
      end
    else
      redirect_to browse_admin_asset_folders_path( @current_folder.path )
    end
  end



  def show
    redirect_to browse_admin_asset_folders_path(@current_folder.path)
  end


  
  def new
    force_subsection "index"
    @asset_folder = AssetFolder.new( :parent_id => @current_folder.id )
    @asset_folder.parent = @current_folder
    render :layout => "admin/manual_sidebar"    
  end


  
  def create
    force_subsection "index"
    
    @asset_folder = AssetFolder.new( params[:asset_folder] )
    @asset_folder.parent_id = params[:asset_folder][:parent_id]
    if @asset_folder.save
      flash[:notice] = "Your folder has been saved"
      redirect_to browse_admin_asset_folders_path( @asset_folder.path )        
    else
      render :action => :new, :layout => "admin/manual_sidebar"
    end
  end
  
  
  
  def edit
    force_subsection "index"
    @asset_folder = AssetFolder.with_id( params[:id] )
    render :layout => "admin/manual_sidebar"
  end
  
  
  
  def update
    force_subsection "index"
    @asset_folder = AssetFolder.with_id( params[:id] )
    @asset_folder.attributes = params[:asset_folder]
    @asset_folder.parent_id = params[:asset_folder][:parent_id]
    if @asset_folder.save
      flash[:notice] = "Changes saved"
      redirect_to browse_admin_asset_folders_path( @asset_folder.path )
    else
      render :action => :edit, :layout => "admin/manual_sidebar" and return
    end
  end
  
  
  
  def destroy
    @asset_folder = AssetFolder.with_id( params[:id] )
    if @asset_folder.parent && @asset_folder.destroy
      flash[:notice] = "Asset folder removed"
      redirect_to browse_admin_asset_folders_path( @asset_folder.parent.path ) and return
    else
      flash[:error] = "Delete failed"
      redirect_to :action => :index and return
    end
  end
  
  
  
  ############################################################################
  # Attachments
  ############################################################################
  
  def attach
    
    @search_suggestion = params[:suggestion]
    
    # Handle uploads
    @asset = Asset.new( :asset_folder_id => @current_folder.id )
    @url_upload = UrlUpload.new( :asset_folder_id => @current_folder.id )
    @google_url_upload = UrlUpload.new( :asset_folder_id => @current_folder.id )
    
    if request.post?
          
      if params[:asset]
                
        @asset = Asset.new( params[:asset] )
        @asset.asset = params[:asset][:asset]
        @asset.user = current_user
        if @asset.save
          flash[:notice] = "Your upload has been saved"
          redirect_to use_attach_admin_asset_folders_path( @asset )
          return
        end
        
      elsif params[:url_upload]
              
        @url_upload = UrlUpload.new( params[:url_upload] )
        @url_upload.user = current_user
        if @url_upload.valid? && @url_upload.convert!
          flash[:notice] = "Upload saved"
          redirect_to use_attach_admin_asset_folders_path( @url_upload.asset )
          return
        end
      
        # Google or normal?
        if params[:google]
          @google_url_upload = @url_upload
          @url_upload = UrlUpload.new( :asset_folder_id => @current_folder.id )
        end
        
      end
      
    end
    
    @assets = (params[:location] == "all") ? Asset.where("asset_folder_id > 0") : @current_folder.assets
    @assets = @assets.where(["assets.title LIKE ?", "%#{params[:q]}%"]) if params[:q]
    @assets = @assets.paginate( :page => params[:page], :per_page => Braincube::Config::AdminAssetPaginationLimit )
    

    
    if request.xhr?
      render :partial => "/admin/assets/attachments/folder", :locals => {:assets => @assets}
      return
    end
    render :layout => "admin/iframe"
  end

  def use_attach
    @asset = Asset.find( params[:id] )
    render :layout => "admin/iframe"
  end
  
  def attach_variation
    @asset = Asset.find( params[:id] )
    render :layout => "admin/iframe"
  end
  
  
  ############################################################################
  # Private helper methods
  ############################################################################
  
  private
  
  def load_folder
    @current_folder = AssetFolder.with_id( params[:path].to_s.split("/").last.to_s.split("-").first.to_i ) rescue nil
    @current_folder ||= AssetFolder.with_id( session[:current_folder].to_i ) rescue nil
    @current_folder ||= AssetFolder.root
    session[:current_folder] = @current_folder.id
  end
  
  
end
