class ActiveSupport::TestCase
  
  def upload_image(name, content_type)
    return Factory( :asset, :asset => Rack::Test::UploadedFile.new(
                            "#{fixture_path}files/images/#{name}", content_type ) )
  end
  
end