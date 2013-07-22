module Braincube::AdminHelper
  
  # General global admin helpers
  ############################################################################
  def page_title
    [@page_title, Braincube::Config::SiteTitle].compact.join(" | ")
  end
  
  
  # Ajax and pagination
  ############################################################################
  def ajax_spinner(base, color=nil)
    image_tag( "admin/spinner#{("_"+color) if color}.gif", :alt => "Loading...", :class => "spinner", :id => "#{base}_spinner" )
  end
  
  def continuous_pagination(name)
    out = "<div id=\"pagination_loading_wrapper\"><div id=\"pagination_loading\">Loading..."
    out << image_tag("/assets/admin/spinner.gif", :alt=>"Loading...", :id => "#{name}_spinner")
    out << "</div></div>"
    return out.html_safe
  end
  
  
  # Action links
  ############################################################################
  
  def delete_link(content, url)
    link_to content, url, :method => :delete, :class => :destroy, :confirm => "Are you sure you want to delete this item?"
  end
  
  def approve_link(content, url)
    link_to content, url, :class => :approve, :method => :post
  end
  
  
  
  # Formatting
  ############################################################################
  
  def print_time( value, options={} )
    options.reverse_merge!( { :if_empty => "unknown", :long => false} )
    return options[:if_empty] unless value && value.is_a?(Time)
    unless options[:long]
      if value > 6.days.ago
        return value.strftime("%I:%M%p on %A")
      end
      return value.strftime("%I:%M%p on %d %b %Y")
    else
      return value.strftime("%I:%M%p on %A %d %B %Y")
    end
  end
  
  def print_bool( value )
    value ? "Yes" : "No"
  end
  
  
  
  
  # Form helpers
  ############################################################################
  
  def labelled_form_for(*args, &block)
    raise ArgumentError, "Missing block" unless block_given?
    options = args.extract_options!.merge( :builder => Braincube::LabelledFormBuilder )
    options[:html] ||= {}
    form_for(*(args << options), &block)
  end
  
  def form_errors(obj)
    errors = obj.errors
    return if errors.blank?
    
    error_messages = obj.errors.map do |msg, content|
      content_tag(:li, 
        msg.to_s.humanize + " " + h(content)
      ) 
    end.join.html_safe
    
    output = "".html_safe
    output << content_tag(:h2, 
      "There #{(errors.size==1 ? "was an error" : "were errors")} "+
      "in your form:"
    ).html_safe
    output << content_tag(:ul, error_messages.html_safe).html_safe
    return content_tag(:div, output, :class=>"errors").html_safe
  end
  
  
  
  # Menu helpers
  ############################################################################
  
  # Top-level admin menu
  def admin_main_menu
    
    out = ""
    
    # Loop through each top-level menu in the AdminMenu hash and output a link.
    # Sort the hash by the order key before doing this.
    Braincube::Config::AdminMenus.sort_by{|h| h[1]["order"] }.each do |title,menu|
      
      # Check if this menu item is visible for this role - do any of the 
      # submenus have access permission for the current user's role?
      visible_for_roles = menu["submenus"].map{|s| s[1]["roles"] }.flatten.uniq.map(&:to_sym)
      
      # If the role is included, work out the path and output a link.
      if visible_for_roles.include?( current_user.role.downcase.to_sym )
        path = "#{ "/admin" unless menu["controllers"].first=="admin"}/#{ menu["controllers"].first }"
        out << content_tag( :li, link_to(title, path), :class => ((menu["controllers"].include?(controller_name)) ? :active : :inactive))
      end
      
    end
    
    return out.html_safe
  end


  # Admin sub menu
  def admin_sub_menu
    
    out = ""
    
    # Find out what section we are in by searching for a matching controller
    current_menu = Braincube::Config::AdminMenus.values.find do |menu|
      menu["controllers"].include?( controller.controller_name )
    end
    
    # No menu!
    return nil unless current_menu
    
    # For each submenu item in the selected submenu, check to see if we can 
    # access as the current user, then render if we can.
    current_menu["submenus"].sort_by{|h| h[1]["order"] }.each do |title,submenu|
      
      # Search all permissions...
      if submenu["roles"].map(&:to_sym).include?( current_user.role.downcase.to_sym )
        
        # Build the path of the request and output the link
        path = "#{ "/admin" unless submenu["controller"]=="admin"}/#{ submenu["controller"] }#{ "/"+submenu["action"] unless submenu["action"]=="index" }"
        out << content_tag( :li, link_to(title, path), :class => (((submenu["controller"] == controller_name) && ((submenu["action"] == action_name) || (submenu["action"] == @forced_active_subsection.to_s)))) ? :active : :inactive)
        
      end
      
    end
    
    return out.html_safe
    
  end
  
  def _admin_sub_menu
    submenu = controller.class.subsections.collect do |mod|
      if mod[:roles].include?( current_user.role.downcase.to_sym )
        path = "/admin/#{controller_name=="admin" ? "" : controller_name + "/"}#{mod[:actions].first==:index ? "" : mod[:actions].first}".chomp("/")
        "<li class=\"#{"in" unless ((mod[:actions].include?(action_name.to_sym) && @forced_active_subsection.blank?)  || @forced_active_subsection==mod[:title]) }active\">#{link_to mod[:title].to_s.humanize, path}</li>"
      end
    end
    return submenu.compact.join("\n").html_safe
  end
  
  
end
