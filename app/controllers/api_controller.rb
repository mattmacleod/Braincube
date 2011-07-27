class ApiController < ApplicationController
  
  # Controller setup
  ############################################################################
  before_filter :validate_code
  after_filter  :record_request, :if => Proc.new { !!@api_key }
  
  
  # API methods
  ############################################################################
  
  # Get users.
  # Valid parameters: role(string), id(integer)
  def users
    
    @users = User.where(:enabled => true)
    @users = @users.where(:role => params[:role].upcase) if params[:role]
    @users = @users.where(:id => params[:id]) if params[:id]
    respond_to do |format|
      format.xml { render :xml => @users.to_xml }
    end
    
  end
  
  # Get events
  # Paramaters: start, end, tag, id, include_performances
  def events

    @events = Event.where(:enabled => true).includes(:performances)
    @events = @events.where("performances.starts_at >= ?", Time::parse(params[:start])) if params[:start]
    @events = @events.where("performances.starts_at <= ?", Time::parse(params[:end])) if params[:end]
    @events = @events.tagged_with_all(params[:tag]) if params[:tag]
    @events = @events.where(:id => params[:id]) if params[:id]    
    respond_to do |format|
      format.xml { render :xml => @events.to_xml( :skip_types => true, :include => ( :performances if params[:include_performances] ) ) }
    end
    
  end
  
  def venues
    
    # Location?
    if params[:location] && (loc = params[:location].split(",").map(&:to_f)).length==3
      @location = { :lat => loc[0], :lng => loc[1] }
      @venues = Venue.in_region(loc[0],loc[1],loc[2]).where(:enabled => true)
    else
      @venues = Venue.where(:enabled => true)
    end
    
    @venues = @venues.includes(:city).where("cities.name LIKE ?", params[:city]) if params[:city]
    @venues = @venues.tagged_with_all(params[:tag]) if params[:tag]
    @venues = @venues.where(:id => params[:id]) if params[:id]
     
    respond_to do |format|
      format.xml do 
          render :xml => @venues.to_xml( 
            :skip_types => true,
            :include => ( :performances if params[:include_performances] ) 
          )
      end
    end
    
  end
  
  def articles
    
    @articles = Article.live
    @articles = @articles.where("updated_at >= ? OR created_at >= ?", Time::parse(params[:since]), Time::parse(params[:since])) if params[:since]
    @articles = @articles.tagged_with_all(params[:tag]) if params[:tag]
    @articles = @articles.where(:id => params[:id]) if params[:id]    

    respond_to do |format|
      format.xml do 
          render :xml => @articles.to_xml( :skip_types => true )
      end
    end
    
  end

  
  # Protected utility methods
  ############################################################################
  private
  
  # Check the the supplied API request is valid.
  def validate_code
    
    # Don't validate in dev mode
    return true if Rails.env=="development"
    
    begin
      
      id    = params[:key].to_s.split("-")[0]
      code  = params[:key].to_s.split("-")[1]
      
      @version = params[:version].to_i
      
      @api_key = ApiKey.find( id )
      if ( @api_key && @api_key.enabled? && @api_key.code==code )
        return true
      else
        reject and return false
      end
      
    rescue
      reject and return false
    end
    
  end
  
  # Reject invalid requests
  def reject
    render :xml=>"", :status => :forbidden
  end
  
  def record_request
    @api_key.record!( request.url, response.status, request.remote_ip, @version )
  end
  
end
