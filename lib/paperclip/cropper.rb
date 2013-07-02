module Paperclip  
  class Cropper < Thumbnail 
     
    def transformation_command
            
      # Get the asset we're working with
      target = @attachment.instance
      
      # Find out what style we are processing
      current_style = Braincube::Config::ImageFileVersions.key( [@options[:geometry], @options[:format]] )
   
      # If the style does not need to be recropped, do what we were already doing
      unless current_style && target.cropping?( current_style )
        return super
      end
      
      # Get the basic processing string    
      s = super
      
      # Remove the crop and resize commands
      if cindex = super.index("-crop")
        s.delete_at cindex
        s.delete_at cindex
      end
      if cindex = super.index("-resize")
        s.delete_at cindex
        s.delete_at cindex
      end
      
      # Get the new crop and resize commands
      commands = get_crop_commands
      
      return commands + s

      
    end

    def get_crop_commands
      
      # Get the asset we're working with
      target = @attachment.instance
      current_style = Braincube::Config::ImageFileVersions.key( [@options[:geometry], @options[:format]] )
      
      # Get the crop attributes supplied to the model
      crop_x = target.send("crop_x_#{current_style}").to_i
      crop_y = target.send("crop_y_#{current_style}").to_i
      crop_w = target.send("crop_w_#{current_style}").to_i
      crop_h = target.send("crop_h_#{current_style}").to_i
      
      # Construct the new crop and resize commands
            
      # Get the geometry
      geom = @options[:geometry].gsub("#", "").to_s
      
      # Get the target size
      height = geom.split("x")[0].to_i
      width = geom.split("x")[1].to_i
      
      # Generate resize parameter
      resize = ["-resize", "'#{geom}'"]
      
      # Generate a crop argument
      crop = ["-crop", "'#{crop_w}x#{crop_h}+#{crop_x}+#{crop_y}'"]
      
      return crop+resize
      
    end
        
  end  
end