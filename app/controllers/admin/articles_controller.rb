class Admin::ArticlesController < AdminController
    
  before_filter :get_article, :only => [:edit, :update, :destroy, :unpublish, :check_lock, :revert_draft]
  
  braincube_permissions(
    { :actions => [:index],       :roles => [:writer, :editor, :subeditor, :publisher, :admin] },
    { :actions => [:unsubmitted], :roles => [:writer, :editor, :subeditor, :publisher, :admin] },
    { :actions => [:editing],     :roles => [:editor, :subeditor, :publisher, :admin] },
    { :actions => [:subediting],  :roles => [:subeditor, :publisher, :admin] },
    { :actions => [:publishing],  :roles => [:publisher, :admin] },
    { :actions => [:download],    :roles => [:writer, :editor, :subeditor, :publisher, :admin] },
    { :actions => [:live],        :roles => [:publisher, :admin] },
    { :actions => [:inactive],    :roles => [:publisher, :admin] }
  )
    
    
    
  # Article listings
  ############################################################################
  def index
    
    @articles ||= current_user.role.downcase.to_sym==:writer ? Article.where(:user_id=>current_user.id).recently_updated : Article.recently_updated

    # Filters
    @articles = @articles.where(:publication_id => params[:publication_id]) if ( params[:publication_id]  && @publication = Publication.find(params[:publication_id]) )
    @articles = @articles.where(:section_id => params[:section_id]) if ( params[:section_id] && @section = Section.find(params[:section_id]) )
    @articles = @articles.where(["articles.title LIKE ? OR cached_authors LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%"]) if !params[:q].blank?
    
    @articles = @articles.order("updated_at DESC").includes(:assets).includes(:drafts).includes(:lock).paginate(:page => params[:page], :per_page => Braincube::Config::AdminPaginationLimit)
    
    @article_count = @articles.total_entries
    
    if request.xhr?
      render :partial => "list", :locals => {:articles => @articles}
      return
    end
    
    render :action => "index"
    
  end
  
  def unsubmitted
    @articles = current_user.role.downcase.to_sym==:writer ? Article.unsubmitted.where(:user_id=>current_user.id) : Article.unsubmitted
    index
  end
  
  def editing
    @articles = Article.editing
    index
  end
  
  def subediting
    @articles = Article.subediting
    index
  end
  
  def publishing
    @articles = Article.ready
    index
  end
  
  def live
    @articles = Article.live
    index
  end
  
  def inactive
    @articles = Article.inactive
    index
  end
  
  def download
    @articles = Article.downloadable
    index
  end
  
  
  
  
  # Main article pages
  ############################################################################
  
  # Show the article in either printable HTML or InDesign format
  def show
    
    # Load the requested article
    @article = Article.find( params[:id] )
    
    respond_to do |format|
      format.html do
        render :layout => "admin/show"    
      end
      
      format.indtt do
        # We are rendering for InDesign Tagged Text format. Need to massage the
        # content into an acceptable format
      
        # Render the template to a string then replace all HTML entities, remove
        # all CRLF line endings, and convert to UTF16 BigEndian (the only 
        # format that InDesign will read without complaining). Need to convert
        # line endings back to CR then, something to do with Mac formatting.
        out_string = HTMLEntities.new.decode( 
          render_to_string.gsub("\r", "\n").gsub(/\n+/, "\n").gsub(/\t+/, "")
        )
        out_string = out_string.gsub("\n", "\r").gsub(/\r+/, "\r").encode("utf-16be")
      
        send_data out_string, 
          :disposition => "attachment; filename=#{@article.id}-#{@article.url}.indesign.txt", 
          :type=>"text/plain; charset=utf-16be"
      end
      
    end
    
  end
  
  
  
  
  
  def edit
    
    # Check if the article is locked
    if @article.locked? && (@article.lock.user == current_user)
      
      # Locked by current user
      @article.lock.update_attribute(:updated_at, Time::now)
      @lock_status = :good
      
    elsif @article.locked?
      
      # Locked by other user!
      @lock_status = :bad
      
    else

      # It is not locked - lock it
      @article.lock!( current_user )
      @lock_status = :good
      
    end

    @article.reload
    @article.load_draft
    
    # Set the subsection to the queue of the article
    force_subsection @article.queue
    
    # Use the sidebar
    render :layout => "admin/manual_sidebar"
    
  end





  def update
    
    # Is this a draft, or a realie?
    if params[:commit] == "Save draft"
    
      success = @article.save_draft( current_user, params[:article] )
      
      # Now find out what we should render
      if request.xhr?
        # We don't unlock, because we're probably still editing
        render :nothing => true and return 
      else
        # Unlock the article (if we have the lock)
        @article.unlock!( current_user )
        flash[:notice] = "Article has been saved as a draft"
        
        # Decide if we are redirecting to the list (if we have permission)
        # or back to the index (if we don't)
        user_can_edit( @article ) ? redirect_to(:action => @article.queue) : redirect_to(:action => :index)
        return
      end
    
    end
    
    # Try to update the article
    if @article.update_attributes( params[:article] )

      # Destroy drafts
      @article.drafts.destroy_all
      
      # Update worked, so we should check what to do next
      if params[:publish_now] && [:publisher, :admin].include?( current_user.role.downcase.to_sym )
         @article.publish_now! 
         @article.reload
      elsif params[:stage_complete]
        @article.stage_complete!
        @article.reload
      end
      
      # Now find out what we should render
      if request.xhr?
        # We don't unlock, because we're probably still editing
        render :nothing => true and return 
      else
        # Unlock the article (if we have the lock)
        @article.unlock!( current_user )
        flash[:notice] = "Article has been saved"
        
        # Decide if we are redirecting to the list (if we have permission)
        # or back to the index (if we don't)
        user_can_edit( @article ) ? redirect_to(:action => @article.queue) : redirect_to(:action => :index)
      end
      
    else
      
      # Failed to update the article. Render XHR or full as required.
      request.xhr? ? render(:nothing => true, :status => 403) : render(:action => :edit, :layout => "admin/manual_sidebar")
    
    end
    
  end
  
  
  
  
  
  def new
    
    # All new articles should force the unsubmitted section to be active
    force_subsection :unsubmitted
    
    # Create the article and set initial attributes
    @article = Article.new
    @article.writer_string = current_user.name
    
    # Render the with manual sidebar for the form
    render :layout => "admin/manual_sidebar"
    
  end
  
  
    
  
  def create
    
    # Create the new article
    @article = Article.new( params[:article] )
    
    # Set protected parameters
    @article.user = current_user

    # Save the article
    if @article.save
      
      # Move to editing queue if submission checkbox ticked
      if params[:publish_now] && [:publisher, :admin].include?( current_user.role.downcase.to_sym )
         @article.publish_now! 
         @article.reload
      elsif params[:stage_complete]
        @article.stage_complete!
        @article.reload
      else
        flash[:notice] = "Article has been saved"
      end
    
      # Return to the index
      redirect_to :action => :index
      
    else
      
      # Render the new article form again, we couldn't save
      force_subsection :unsubmitted
      render :action => :new, :layout => "admin/manual_sidebar"
      
    end
    
  end
  
  
  
  
  def revert_draft
    @article.drafts.destroy_all
    flash[:notice] = "Draft have been reverted"
    redirect_to edit_admin_article_path( @article )
  end
  
  
  
  def destroy
    @article.update_attribute(:status, Article::Status[:removed])
    flash[:notice] = "Article has been obliterated"
    redirect_to :action => :index
  end
  
  
  
  
  def unpublish
    @article.update_attribute(:status, Article::Status[:ready])
    flash[:notice] = "Article has been removed from the live site"
    redirect_to :action => :publishing
  end
  
  
  
  
  def check_lock
    
    # Check if the article is locked
    if @article.locked? && (@article.lock.user == current_user)
      
      # Locked by current user
      @article.lock.update_attribute(:updated_at, Time::now)
      type = :good
      
    elsif @article.locked?
      
      # Locked by other user!
      type = :bad
      
    else

      # It is not locked - lock it
      @article.lock!( current_user )
      type = :good
      
    end
    
    @article.reload
    render :partial => "lock_info", :locals => {:article => @article, :lock_status => type}
    
  end
  
  
  
  
  
  # Private
  ############################################################################
  
  private
  
  
  # Get the sections and publictions - needed pretty much all over
  def load_defaults
    @all_sections = Section.order(:name)
    @all_publications = Publication.order("date_street DESC").all.group_by(&:direction).to_a
  end
  
  
  # Load the article - anc check if the user can edit it
  def get_article
    
    @article = Article.find(params[:id])
    
    unless user_can_edit( @article )
      flash[:error] = "You do not have permission to edit that article"
      render :nothing => true and return if request.xhr?
      redirect_to admin_articles_path and return false
    end
    
  end
  
  def user_can_edit(article)
    case (article.status)
    when Article::Status[:unsubmitted]
      allowed = [:editor, :subeditor, :publisher, :admin].include?(@current_user.role.downcase.to_sym) || (@article.user==@current_user)
    when Article::Status[:editing]
      allowed = [:editor, :subeditor, :publisher, :admin].include?(@current_user.role.downcase.to_sym)
    when Article::Status[:subediting]
      allowed = [:subeditor, :publisher, :admin].include?(@current_user.role.downcase.to_sym)
    when Article::Status[:ready]
      allowed = [:publisher, :admin].include?(@current_user.role.downcase.to_sym)
    when Article::Status[:published]
      allowed = [:publisher, :admin].include?(@current_user.role.downcase.to_sym)
    when Article::Status[:removed]
      allowed = false
    end
    
    return allowed
  end
  
end
