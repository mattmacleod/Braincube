class UrlUpload < ActiveRecord::Base
  
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
  column :url, :string
  
    
  # Model definition
  ############################################################################
  
  attr_accessor :asset
  
  # Relationships
  belongs_to :user
  belongs_to :asset_folder
  
  # Validation
  validates_presence_of :title, :user, :asset_folder, :url


  # Convert into asset object
  ############################################################################
      
  def convert!
    
    # Download the file
    begin
      
      # Do the download
      response = Net::HTTP.get_response( URI.parse(url) )
      unless response.is_a? Net::HTTPSuccess
        errors.add( :url, "could not be found. Please check and try again." )
        return false
      end
      
      # Get the name of the file to use
      filename = URI.split(url)[5].to_s.split("/").last
      
      # Save the body into a temp file
      dir = Dir.mktmpdir
      file = File.new( File.join(dir, filename), "w" )
      file << response.body
      file.flush
      file.close
      
    rescue
      errors.add( :url, "could not be loaded. Please check and try again." )
      return false
    end
    
    # Get a handle on the downloaded file
    asset_file = File.new( file.path )
    
    # Create asset
    asset = Asset.new( 
      :title => self.title, :caption => self.caption, :credit => self.credit,
      :user_id => self.user_id, :asset_folder_id => self.asset_folder_id
    )
    asset.asset = asset_file
    asset.asset_content_type = asset_file.content_type
    asset.asset_file_name = filename
    asset.asset_file_size = asset_file.size
    
    # Try to save the asset
    unless asset.save
      errors.add( :url, "did not contain a valid asset file." )
      return false    
    else
      @asset = asset
      return true
    end
    
  end
      
end