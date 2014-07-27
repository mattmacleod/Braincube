
class Asset < ActiveRecord::Base
  
  # Model definition
  ############################################################################
  
  ImageContentTypes = ["application/pdf", "image/jpeg", "image/pjpeg", "image/png", "image/x-png", "image/gif"]
  
  # Relationships
  belongs_to :user
  belongs_to :asset_folder
  has_many :asset_links, :dependent => :destroy
  has_many :items, :through => :asset_links
  
  # Validation
  validates_presence_of :title, :user, :asset_folder, :asset
  before_validation :derive_title_from_filename

  # Sort by title by default
  default_scope :order => 'title ASC'
  
  
  def get_caption
    caption.blank? ? title : caption
  end
  
  # Paperclip details
  ############################################################################
  Paperclip.interpolates("custom_id_path") do |attachment,style|
    id = attachment.instance.id.to_i
    id < 100000 ? attachment.instance.id.to_s : ("%09d" % id).scan(/\d{3}/).join("/")
  end

  # Setup the attachment
  if Braincube::Config::AssetStorageMethod == :s3
    has_attached_file :asset, :styles => Braincube::Config::ImageFileVersions,
        :path => ":id/:id_:style.:extension",
        :default_url => "asset_placeholders/:style.png",
        :convert_options => { :all => "-type truecolor -set colorspace RGB -strip -colorspace RGB" },
        :whiny => true,
        :storage => :s3,
        :s3_credentials => Braincube::Config::S3ConnectionDetails[ Rails.env ],
        :bucket => Braincube::Config::S3AssetBucketName[ Rails.env ],
        :url => ":s3_domain_url",
        :s3_options => { :server =>  "#{Braincube::Config::S3AssetBucketName[ Rails.env ]}.s3.amazonaws.com" },
        :processors => [:cropper],
        :s3_protocol => "https"
    
  else
    has_attached_file :asset, :styles => Braincube::Config::ImageFileVersions,
        :path => ":rails_root/public/assets/:rails_env/:custom_id_path/:id_:style.:extension",
        :url => "/assets/:rails_env/:custom_id_path/:id_:style.:extension",
        :default_url => "/images/asset_placeholders/:style.png",
        :convert_options => { :all => "-set colorspace sRGB -strip -colorspace sRGB" },
        :processors => [:cropper], :whiny => true
  end
  
  # Validate attachments
  validates_attachment_size :asset, :less_than => Braincube::Config::AssetMaxUploadSize
  validates_attachment_presence :asset
  validates_attachment_content_type :asset, :content_type => Braincube::Config::AssetContentTypes
     
                          
  # Prevents Paperclip from making thumbnails of non-image files by telling it
  # not to post-process if the content-type isn't an image.
  define_callbacks :post_process, :terminator => "result == false"
  set_callback(:post_process, :before, :image?)
  def image?
    return ImageContentTypes.include?(self.asset_content_type)
  end
  
  # Returnt the type of this asset so we know how to display it on the front end
  def asset_type
    
    if asset_content_type=="application/pdf"
      return :pdf
    elsif image?
      return :image
    elsif asset_content_type=="application/msword"
      return :doc
    elsif asset_content_type=="application/vnd.ms-excel"
      return :xls
    elsif asset_content_type=="application/zip"
      return :zip
    else
      return :generic
    end
    
  end
  
  # Handle cropping
  after_update :reprocess_cropped_styles
  Braincube::Config::ImageFileVersions.keys.each do |k|
    attr_accessor "crop_x_#{k}", "crop_y_#{k}", "crop_w_#{k}", "crop_h_#{k}"
  end
  def reprocess_cropped_styles 
    return if @updated
    @updated = true
    Braincube::Config::ImageFileVersions.keys.select{|k| cropping?( k )}.each do |style|
      asset.reprocess!( style )
    end
  end
  def cropping?( style )
    ["crop_x_#{style}", "crop_y_#{style}", "crop_w_#{style}", "crop_h_#{style}"].flatten.any?{|a| !(self.send(a).blank?) }
  end

  def derive_title_from_filename
    return unless title.blank? && asset && asset.original_filename
    self.title = self.class.filename_to_title( asset.original_filename )
  end
  def self.filename_to_title(str)
    str.to_s.split(".")[0..-2].join(".").gsub(/[_\-]/, " ").gsub(/\s+/, " ").strip.gsub(/^(.)/){ $1.capitalize }
  end
end
