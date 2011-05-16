module Admin::TagsHelper
  
  def tag_manager_link( tag )
    content_tag(
      :span,
      link_to( tag.name, admin_tag_path(tag), :class => "show" )+
      link_to( "delete tag", admin_tag_path(tag), :class => "delete", :method => :delete ),
      :class => "tag"
    )
  end
  
  def tag_attachment_link( tag )
    link_to( tag.name, "#", :class => "tag", :title => tag.name )
  end
  
end
