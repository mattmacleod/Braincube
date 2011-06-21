class BraincubeMainController < BraincubeApplicationController
  
  # Generic site front-end requirements inherit from here, because 
  # ApplicationController will also be inherited by AdminController
  before_filter :load_page, :load_defaults
  
  
  # Home page
  def index
    @articles = Article.live.order("starts_at DESC").limit(6).includes(:asset_links => :asset)    
  end
  
  
  private
  
  # Load default data that we need on many pages
  def load_defaults
    @root_page      = Page.root
    @top_level_page = @page.ancestors[1] || @root_page
  end

  # Find out what the current page is, then load it plus properties and widgets
  def load_page
    @page         = params[:page_id].blank? ? Page.root : Page.find( params[:page_id] )
    redirect_to admin_setup_path and return unless @page
    @pp           = @page.properties
    @page_title   = @page.title
    @widget_slots = @page.widgets_by_slot
  end
  
  def get_per_page( supplied=0 )
    supplied.to_i==0 ? Braincube::Config::ItemsPerPage : supplied.to_i
  end
  
  def request_id( param )
    param.to_s.split("-").first
  end
  
end
