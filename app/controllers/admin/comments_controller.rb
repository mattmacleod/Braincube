class Admin::CommentsController < AdminController
  
  # Define controller subsections
  braincube_permissions(
    { :actions => [:index, :show, :edit, :update, :new, :create], :roles => [:admin, :publisher] }
  )
  
  # Lists
  ############################################################################
  
  def index
    @comments = Comment.order("created_at DESC")
    @comments = @comments.where(["comments.name LIKE ? OR comments.email LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%"]) if params[:q]
    @comments = @comments.paginate( :page => params[:page], :per_page => Braincube::Config::AdminPaginationLimit )
    if request.xhr?
      render(:partial => "list", :locals => {:comments => @comments})
      return
    end
  end
 
   
  # Individual users
  ############################################################################
  
  def new
    display_404
  end
  
  def create
    display_404
  end
  
  def show
    redirect_to :action => :edit 
  end
  
  def edit
    @comment = Comment.find( params[:id] )
    render( :layout => "admin/manual_sidebar" )
  end
  
  def update
    @comment = Comment.find( params[:id] )
    @comment.attributes = params[:comment]
    
    # Save the record
    if @comment.save
      flash[:notice] = "Comment has been saved"
      redirect_to( :action => :index )
    else
      render( :action => :edit, :layout => "admin/manual_sidebar" )
    end
    
  end
  
  def destroy
    @comment = Comment.find( params[:id] )
    if @comment.destroy
      flash[:notice] = "Comment deleted"
    end
    redirect_to :action => :index
  end
  
  def approve
    @comment = Comment.find( params[:id] )
    @comment.update_attribute(:approved, true)
    if request.xhr?
      render :nothing => true, :status => 200
    else
      flash[:notice] = "Comment approved"
      redirect_to :action => :index
    end
  end
  
end
