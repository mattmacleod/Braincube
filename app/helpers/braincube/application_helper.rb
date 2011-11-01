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
    	if defined?( Braincube::Application )
  		  out << include_stylesheets(group, :media => "all")
  		  out << include_javascripts(group)
  		else
  			out << '<!--[if (!IE)|(gte IE 8)]><!-->'
  			out << '<link href="/packages/' + group.to_s + '-datauri.css?' + Braincube::Version + '" media="all" rel="stylesheet" type="text/css" />'
  			out << '<!--<![endif]-->'
  			out << '<!--[if lte IE 7]>'
  			out << '<link href="/packages/' + group.to_s + '.css" media="all" rel="stylesheet" type="text/css" />'
  			out << '<![endif]-->'
  			out << '<script src="/packages/' + group.to_s + '.js?' + Braincube::Version + '" type="text/javascript"></script>'
  	  end
	  elsif group == :braincube_show_article
	    if defined?( Braincube::Application )
	      out << include_stylesheets(:braincube_show_article, :media => "all")
  		  out << include_stylesheets(:braincube_print_article, :media => "print")
		  else
        out << '<!--[if (!IE)|(gte IE 8)]><!-->'
        out << '<link href="/packages/braincube_show_article-datauri.css?' + Braincube::Version + '" media="all" rel="stylesheet" type="text/css" />'
        out << '<link href="/packages/braincube_print_article-datauri.css?' + Braincube::Version + '" media="print" rel="stylesheet" type="text/css" />'
        out << '<!--<![endif]-->'
        out << '<!--[if lte IE 7]>'
        out << '<link href="/packages/braincube_show_article.css" media="all" rel="stylesheet" type="text/css" />'
        out << '<link href="/packages/braincube_print_article.css" media="print" rel="stylesheet" type="text/css" />'
        out << '<![endif]-->'
      end
    end
    
	  return out.html_safe
	  
  end
  
end
