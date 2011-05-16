module Admin::PagesHelper
  
  def page_tree( root )

    force_open = @updated_page ? @updated_page.ancestors.include?(root) : false
    
     if root.children.length > 0
       content_tag :li, page_tree_element(root) +
       content_tag(:ul, root.children.map{|p| page_tree(p) }.join.html_safe ), 
       :id => "page_node_#{root.id}",
       :class => (root.parent==nil || force_open) ? "jstree-open" : "jstree-closed"
     else
       content_tag :li, page_tree_element(root), 
       :id => "page_node_#{root.id}"
     end
   end
   
   def page_options( page, selected_id, prefix="" )
     if page.children.length > 0
       content_tag(:option, "#{prefix} #{page.title}".strip, "data-path" => page.url, :value => page.id, :selected => (selected_id==page.id)) +
       page.children.map{|f| page_options(f, selected_id, "#{prefix}--") }.join.html_safe
     else
       content_tag :option, "#{prefix} #{page.title}".strip, "data-path" => page.url, :value => page.id, :selected => (selected_id==page.id)
     end
   end
   
   def page_tree_element( page ) 
     classes = []
     classes << :highlighted if @updated_page==page
     classes << :timed if !page.live? && page.enabled?
     classes << :disabled if !page.live? && !page.enabled?
     
     link_to(page.title, edit_admin_page_path( page ), :class => classes.join(" ")) + link_to( "Add a child page", new_admin_page_path(:parent_id => page.id), :class => "add_child")
   end
   
   def new_page_widget_form( form, slot )
     javascript_tag "var global_page_widget_string_#{slot} = \"#{ escape_javascript render(:partial => '/admin/pages/page_widget', :locals => { :f => form, :page_widget => PageWidget.new(:slot => slot) }) }\""     
   end
   
end
