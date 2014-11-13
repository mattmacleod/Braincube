module Braincube::ApplicationHelper
  
  # General helpers
  ############################################################################
  
  def page_title
    [@page_title, Braincube::Config::SiteTitle].compact.join(" | ")
  end
  
  def flash_message
    return unless flash
    return [:error, :warning, :notice].map do |flash_type|
      unless flash[flash_type].blank?
      	"<div class=\"flash_wrapper\"><div class=\"flash flash_#{flash_type}\"><span class=\"icon #{flash_type}\"></span><span class=\"text\">#{flash[flash_type]}</span></div></div>"
      end 
    end.join.html_safe
  end
  
  def note(content, options={})
    options.reverse_merge!( {:type=>:info} )
    output = "<div class=\"note #{options[:type]}\">"+
             "<span class=\"icon #{options[:type]}\"></span><span class=\"text\">#{content}</span>"+
             "</div>"
    return output.html_safe
  end
  
  def include_assets( group = :braincube_admin )
    out = ""
    
    if group == :braincube_admin
		  out << stylesheet_link_tag("admin/styles", :media => "all").to_s
		  out << javascript_include_tag("admin/admin").to_s
	  elsif group == :braincube_show_article
      out << stylesheet_link_tag(:braincube_show_article, :media => "all")
		  out << stylesheet_link_tag(:braincube_print_article, :media => "print")
    end
    
	  return out.html_safe
	  
  end
  
end
