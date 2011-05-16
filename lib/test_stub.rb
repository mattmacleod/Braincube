UrlUpload.class_eval do
  
  def convert!
    @asset = Asset.first
    return true
  end
  
end