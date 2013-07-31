module Admin::AssetsHelper
  
  def get_folder_url(folder)
    controller.action_name == "attach" ? attach_admin_asset_folders_path(folder.path) : browse_admin_asset_folders_path(folder.path)
  end
  
  def asset_folder_tree(folder)
    path = get_folder_url(folder)
    
    c = folder.get_children
    if c.length > 0
      "<li><a href='#{path}' class='#{("current" if @current_folder.id==folder.id)}'>#{folder.name}</a><ul> #{c.map{|f| asset_folder_tree(f) }.join} </ul></li>".html_safe
    else
      "<li><a href='#{path}' class='#{("current" if @current_folder.id==folder.id)}'>#{folder.name}</a></li>".html_safe
    end
  end
  
  def asset_folder_options(folder, selected_id, prefix="")
    if folder.get_children.length > 0
      content_tag(:option, "#{prefix} #{folder.name}".strip, :value => folder.id, :selected => (selected_id==folder.id)) +
      folder.get_children.map{|f| asset_folder_options(f, selected_id, "#{prefix}--") }.join.html_safe
    else
      content_tag :option, "#{prefix} #{folder.name}".strip, :value => folder.id, :selected => (selected_id==folder.id)
    end
  end
  
  ############################################################################
  # Image attachment
  ############################################################################
  
  def image_attachments( f )
    render :partial => "/admin/assets/attachments/form", :locals => { :f => f, :image_only => true }
  end
  
  def new_asset_attachment_form( form )
    javascript_tag("var global_asset_link_string = \"#{  }\"")
  end
  
end
