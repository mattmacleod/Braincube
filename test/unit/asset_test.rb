require File.dirname(__FILE__) + '/../test_helper'
require "ftools"

class AssetTest < ActiveSupport::TestCase

  # Metatests
  ############################################################################
  should_be_valid_with_factory


  # Model definition
  ############################################################################
  should belong_to :asset_folder
  should belong_to :user
  should have_many :asset_links
  should have_many(:items).through(:asset_links)
  
  should validate_presence_of :title
  should validate_presence_of :user
  should validate_presence_of :asset_folder
  
  should have_db_index :asset_folder_id
  
  # Upload tests
  ###########################################################################
  #
  # We test images first. Don't re-test with every format, because it's slow!
      
  context "Uploading a large RGB JPEG image" do
    
    setup do
      @asset = upload_image("test_image_large_rgb.jpg", "image/jpeg")
    end

    should "create the correct files" do
      assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_original.jpg")
      Braincube::Config::ImageFileVersions.each_pair do |k,v|
        assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg")
      end
    end
    should "have an RGB colorspace" do
      assert Magick::Image.read("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_large.jpg").first.colorspace == Magick::RGBColorspace
    end
        
  end
  
  
  # Check CMYK conversion here 
  context "Uploading a large CMYK JPEG image" do
    
    setup do
      @asset = upload_image("test_image_large_cmyk.jpg", "image/jpeg")
    end
    
    should "convert the asset to an RGB colorspace" do
      assert_equal Magick::RGBColorspace, Magick::Image.read("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_large.jpg").first.colorspace
    end
    should "not alter the color space of the original image" do
      assert_equal Magick::CMYKColorspace, Magick::Image.read("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_original.jpg").first.colorspace
    end
    
  end

  # Check GIF upload
  context "Uploading a large GIF image" do
    
    setup do
      @asset = upload_image("test_image_large.gif", "image/gif")
    end

    should "create the correct files" do
      assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_original.gif")
      Braincube::Config::ImageFileVersions.each_pair do |k,v|
        assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg")
      end
    end    
    
  end
  
  # Check PNG upload
  context "Uploading a large PNG image" do
    
    setup do
      @asset = upload_image("test_image_large.png", "image/png")
    end
    
    should "create the correct files" do
      assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_original.png")
      Braincube::Config::ImageFileVersions.each_pair do |k,v|
        assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg")
      end
    end    
    
  end
  
  # Check that small images are not wrongly scaled up
  context "Uploading a small image" do
  
    setup do
      @asset = upload_image("test_image_small_rgb.jpg", "image/jpeg")
    end
    
    # Bit specific - anything we can do to make this better?
    should "not resize any images with the > geometry modifier" do
      not_to_be_scaled = Braincube::Config::ImageFileVersions.select{|k,v| v[0]=~/\>/ }
      not_to_be_scaled.each do |n|
        image = Magick::Image.read("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{n[0]}.jpg").first
        assert_equal 160, image.columns
        assert_equal 160, image.rows
      end
    end
    
  end
  
  
  # PDFs should create first-page thumbnails
  ###########################################################################
  
  context "A RGB 1.5 PDF upload" do
    setup do
      @asset = upload_image("test_rgb_1.5.pdf", "application/pdf")
    end
    should "produce thumbnails" do
      assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_original.pdf")
      Braincube::Config::ImageFileVersions.each_pair do |k,v|
        assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg")
        assert_equal Magick::RGBColorspace, Magick::Image.read("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg").first.colorspace
      end
    end
  end
  
  context "A RGB 1.7 PDF upload" do
    setup do
      @asset = upload_image("test_rgb_1.7.pdf", "application/pdf")
    end
    should "produce thumbnails" do
      assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_original.pdf")
      Braincube::Config::ImageFileVersions.each_pair do |k,v|
        assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg")
        assert_equal Magick::RGBColorspace, Magick::Image.read("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg").first.colorspace
      end
    end
  end
  
  context "A CMYK 1.4 PDF upload" do
    setup do
      @asset = upload_image("test_cmyk_1.4.pdf", "application/pdf")
    end
    should "produce thumbnails" do
      assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_original.pdf")
      Braincube::Config::ImageFileVersions.each_pair do |k,v|
        assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg")
        assert_equal Magick::RGBColorspace, Magick::Image.read("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg").first.colorspace
      end
    end
  end
  
  context "A CMYK 1.7 PDF upload" do
    setup do
      @asset = upload_image("test_cmyk_1.7.pdf", "application/pdf")
    end
    should "produce thumbnails" do
      assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_original.pdf")
      Braincube::Config::ImageFileVersions.each_pair do |k,v|
        assert File::exists?("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg")
        assert_equal Magick::RGBColorspace, Magick::Image.read("#{Rails.root}/public/assets/test/#{@asset.id}/#{@asset.id}_#{k.to_s}.jpg").first.colorspace
      end
    end
  end
end