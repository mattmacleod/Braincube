class Admin::ManagementController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index], :roles => [:admin] }
  )
  
  # Main page
  ############################################################################
  
  def index

  end
  
end
