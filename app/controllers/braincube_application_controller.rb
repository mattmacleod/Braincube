class BraincubeApplicationController < ActionController::Base
  protect_from_forgery
  
  helper Admin::ArticlesHelper
  helper Admin::AssetsHelper
  helper Admin::EventsHelper
  helper Admin::PagesHelper
  helper Admin::TagsHelper
  helper Braincube::AdminHelper
  helper Braincube::ApplicationHelper
  
  # General-use error handlers
  ############################################################################
  
  def display_404
    render "/public/404.html", :status => 404, :layout => false
  end
  
  protected
  
  # User login methods
  ############################################################################
  
  helper_method :current_user, :logged_in?, :is_admin?
  
  def current_user
    return @current_user if @current_user
    if session[:user_id]
      @current_user = User.find( :first, :conditions=>{:id => session[:user_id]} ) 
      if ((@current_user && !@current_user.accessed_at || (@current_user.accessed_at > (Time::now - Braincube::Config::SessionTimeout))))
        @current_user.update_attribute(:accessed_at, Time::now)
      end
      return @current_user
    end
  end
  
  def logged_in?
    !!current_user
  end
  
  def is_admin?
    logged_in? && Braincube::Config::AdminRoles.include?( current_user.role )
  end
  
  # Put together a nice export filename
  def export_filename_for( type = :export, extension = :csv )
    return "#{ type }_#{ Time::now.strftime("%Y%m%d%H%M%S") }.#{extension}"
  end
  
  #
  # Handle role filtering using controller methods
  #

  # Find all of the actions in the subsections method. Then create 
  # before_filters for each of these, with the roles that have access.
  def self.braincube_permissions( *values )

    values.each do |subsection|
      before_filter Proc.new{
        if subsection[:roles].include? current_user.role.downcase.to_sym
          return true
        else
          redirect_to admin_error_403_path and return false
        end
      }, :only => subsection[:actions]
    end

  end
  
end
