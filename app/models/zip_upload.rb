class ZipUpload < ActiveRecord::Base
  
  require "zip"
  require "mime/types"
  
  # Table-less model
  class_attribute :columns
  self.columns = []

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end
    
  column :user_id, :integer
  column :asset_folder_id, :integer
  column :title, :string
  column :caption, :string
  column :credit, :string
  column :upload_content_type, :string
  column :upload_file_name, :string
  column :upload_file_size,  :integer
  
    
  # Model definition
  ############################################################################
  
  # Define accessors - this is a non-DB model!
  attr_accessor 
  
  # Relationships
  belongs_to :user
  belongs_to :asset_folder
  
  # Validation
  validates_presence_of :title, :user, :asset_folder, :upload_file_name, 
                        :upload_content_type, :upload_file_size

  
  # Paperclip details - use for validating the file. Sneaky.
  ############################################################################
  
  # Setup the attachment
  has_attached_file :upload
  
  # Validate attachment
  validates_attachment_presence :upload
  validates_attachment_content_type :upload, :content_type => ["application/zip", "application/octet-stream", "application/x-zip-compressed"]


  # Convert into asset objects
  ############################################################################
      
  def convert!
    
    begin
            
      # Unzip the uploaded file
      uploaded_zip = tempfile
      unzip_dir = Dir.mktmpdir
      asset_files = []
    
      Zip::ZipFile.open( uploaded_zip.path ) do |zip_file|
        zip_file.each do |asset|
          output_path = File.join( unzip_dir, asset.name )
          FileUtils.mkdir_p( File.dirname( output_path ) )
          zip_file.extract( asset, output_path ) unless File.exist?( output_path )
          asset_files << File.new( output_path )
        end
      end
      
      # Process the asset files to remove directories and dotfiles
      asset_files = asset_files.select{|f| !(File.directory?(f)) && !( File.basename(f.path) =~ /^\./ ) }
      
    rescue
      errors.add( :upload, "could not be processed. Is it a valid ZIP file?" )
      return false
    end
    
    # Create a new folder for the assets
    unless (new_asset_folder = AssetFolder.new( :name => self.title, :parent_id => self.asset_folder_id )).save
      errors.add( :asset_folder, "could not be created. Has the title already been used?" )
      return false
    end
        
    # Create assets using the unzipped files
    assets = []
    asset_files.each do |asset_file|
            
      # Get the MIME type of the file
      mime_type = MIME::Types::type_for( asset_file.path )[0].simplified rescue "application/octet-stream"
      
      # Use the filename as the title
      fname = File.basename(asset_file.path, File.extname(asset_file.path) )
      
      asset = Asset.new( 
        :title => fname, :caption => self.caption, :credit => self.credit,
        :user_id => self.user_id, :asset_folder_id => new_asset_folder.id
      )
      asset.asset = asset_file
      asset.asset_content_type = mime_type
      asset.save
      assets << asset
    end
     
    # Did we find assets?
    if assets.empty?
      new_asset_folder.destroy
      errors.add( :upload, "did not contain any valid asset files. Please check the contents of the ZIP." )
      return false
    end

    # Were there any errors?
    if assets.map{|a| a.errors.length }.all?{|e| e > 0 }
      new_asset_folder.destroy
      errors.add( :upload, "contained no valid asset files. Please check the contents of the ZIP." )
      return false    
    else
      # Some errors maybe, but at least one asset was okay, so we're good
      return true
    end
    
  end
  
  private
  
  def tempfile 
    return upload.queued_for_write[:original] if upload.queued_for_write 
    nil 
  end
      
end