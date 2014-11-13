class Admin::AssetsController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :new, :create, :edit, :destroy, :update, :browse], :roles => [:admin, :publisher, :subeditor] }
  )
  
  before_filter :load_folder
  
  def index
    redirect_to admin_asset_folders_path
  end
  
  def show
    redirect_to edit_admin_asset_path(params[:id])
  end
  
  def new
    @asset = Asset.new( :asset_folder_id => @current_folder.id )
    render :layout => "admin/manual_sidebar"
  end
  
  def create
    force_subsection "new"
    @asset = Asset.new( params[:asset] )
    @asset.asset = params[:asset][:asset]
    @asset.user = current_user
    if @asset.save
      flash[:notice] = "Your upload has been saved"
      redirect_to browse_admin_asset_folders_path( @asset.asset_folder.path )
    else      
      render :action => :new, :layout => "admin/manual_sidebar" and return
    end
  end
  
  def edit
    force_subsection "index"
    @asset = Asset.find( params[:id] )
    render :layout => "admin/manual_sidebar"
  end
  
  def update
    force_subsection "index"
    @asset = Asset.find( params[:id] )
    @asset.attributes = params[:asset]
    @asset.asset = params[:asset][:asset] unless params[:asset][:asset].nil?
    if @asset.save
      flash[:notice] = "Changes saved"
      redirect_to browse_admin_asset_folders_path( @asset.asset_folder.path )
    else
      render :action => :edit, :layout => "admin/manual_sidebar" and return
    end
  end
  
  def destroy
    force_subsection "index"
    @asset = Asset.find(params[:id])
    if @asset.destroy
      flash[:notice] = "Asset removed"
    end
    redirect_to browse_admin_asset_folders_path( @asset.asset_folder.path ) and return
  end
  
  def dnd_create
    @asset       = Asset.new
    @asset.asset = params[:asset][:asset]
    @asset.user  = current_user
    @asset.title = params[:asset][:asset].original_filename.split(".")[0..-2].join(".").gsub(/[_\-]/, " ").gsub(/\s+/, " ").strip.gsub(/^(.)/){ $1.capitalize }
    @asset.asset_folder = @current_folder unless @asset.asset_folder
    if @asset.save
      render :partial => "admin/asset_folders/asset.html.haml", :locals => { :asset => @asset }
    else
      head 400
    end
  end

  ############################################################################
  # ZIP uploads
  ############################################################################
  
  def zip_upload
    force_subsection "index"
    @zip_upload = ZipUpload.new( :asset_folder_id => @current_folder.id )
    render :layout => "admin/manual_sidebar"
  end
  
  def create_from_zip
    force_subsection "index"
    @zip_upload = ZipUpload.new( params[:zip_upload] )
    @zip_upload.user = current_user
    if @zip_upload.valid? && @zip_upload.convert!
      new_folder = AssetFolder.nodes.last
      flash[:notice] = "Bulk upload saved - found #{new_folder.assets.length} assets"
      redirect_to browse_admin_asset_folders_path( new_folder.path )
    else
      render :action => :zip_upload, :layout => "admin/manual_sidebar" and return
    end
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