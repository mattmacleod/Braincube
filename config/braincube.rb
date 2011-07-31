# Default configuration file

class Braincube::Config
  
  
  # Site configuration
  ############################################################################
  SiteTitle   = "Braincube"
  SiteEmail   = "hello@braincu.be"
  SiteBaseUrl = "http://www.braincu.be"
  
  
  # Admin settings
  ############################################################################
  AdminDisableArticleTabs = false
  
  
  # Access and authentication
  ############################################################################
  SessionTimeout = 4.hours
  AdminRoles     = ["ADMIN", "PUBLISHER","SUBEDITOR", "EDITOR", "WRITER"]
  
  
  # Validation
  ############################################################################
  EmailRegexp =  /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  UrlRegexp   =  /[a-zA-Z0-9_]+/i
  
  
  # Article  and page types
  ############################################################################
  ArticleTemplates  = ["Normal"]  
  ArticleTypes  = { 
    :feature       => "Feature",
    :review        => "Review",
    :blog_post     => "Blog post",
    :gallery       => "Gallery",
    :video         => "Video"
  } 
  PageTypes = {
    :home        => "Home page",
    :section     => "Landing page",
    :articles    => "Article listing",
    :events      => "Event listing",
    :venues      => "Venue listing",
    :text        => "Static text",
    :contact     => "Contact form"
  }
  PageSortOrder = {
    :newest => "Newest",
    :name   => "Alphabetical",
    :start  => "Upcoming"
  }
  
  
  # Image file types
  # Magick geometry string. Always leave :thumb in this list or bad things will
  # happen elsewhere. You've been warned.
  ############################################################################
  ImageFileVersions = { 
    :large   => ["900x675>",   :jpg],
    :wide    => ["540x",      :jpg],
    :article => ["220x",      :jpg],
    :thumb   => ["125x100#",  :jpg],
    :tiny    => ["60x40#",    :jpg]
  }
  
  
  # Asset uploading
  ############################################################################
  AssetStorageMethod = :filesystem
  AssetMaxUploadSize = 20.megabytes
  AssetContentTypes = [
    "image/jpeg", "image/pjpeg", "image/png", "image/x-png", "image/gif",
    "application/pdf", "application/msword", "application/vnd.ms-excel",
    "application/zip"
  ]
  
  
  # Admin menus
  ############################################################################
  AdminMenus = YAML::load( File.read( File.dirname(__FILE__) + '/braincube_menu.yml' ) )
  
  
  # API keys
  ############################################################################
  GoogleApiKey = "ABQIAAAA_a2Y8YnvGdeGgoGFUyYotBT2yXp_ZAY8_ufC3CFXhHIE1NvwkxQDT74lJaTBe_PAvumnRp3_dubVrg"
  
  
  # Mapping
  ############################################################################
  DefaultAdminMapLocation = "53.800651,-4.042969"
  
  
  # Event options
  ############################################################################
  AffiliateCodes = {
    "Ticket Master" => "ticketmaster"
  }
  
  TicketTypes = {
    "Unticketed" => "unticketed",
    "Sold out" => "sold_out",
    "On the door" => "on_door",
    "Advance purchase" => "advance"
  }
  
  
  # Limits for UI in admin
  ############################################################################
  AdminPaginationLimit = 50
  AdminAssetPaginationLimit = 20
  EventAttachmentLimit = 20
  VenueAttachmentLimit = 20
  
  
  # Widgets
  ############################################################################
  WidgetTypes = {
    :custom_html     => "Custom HTML",
    :image           => "Image link"
  }

  WidgetSlots = {
    :sidebar      => "Sidebar 1"
  }
  
end