Factory.define :asset do |f|
  # The default asset factory produces an image from one of the test fixture]
  # images. Should add additional factories for PDFs, DOCs etc.
  f.association :asset_folder
  f.association :user
  f.title "Test asset"
  f.asset { Rack::Test::UploadedFile.new(
                   "#{Rails.root}/test/fixtures/files/images/test_image_small_rgb.jpg",
                   "image/jpeg" )
          }
end