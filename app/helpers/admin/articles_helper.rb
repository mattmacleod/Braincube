module Admin::ArticlesHelper
  
  
  # Small element helpers
  ############################################################################
  
  def admin_review_stars( article )
    return unless article.review? && article.review_rating.to_i > 0
    content_tag(
      :span,
      (1..article.review_rating).map{|n| 
        image_tag("admin/embed/icons/inline_star.png", :title => pluralize(article.review_rating, "star"), :alt=> pluralize(article.review_rating, "star") )
      }.join.html_safe,
      :class=>"review_rating"
    )
  end
  
  
  
  # Action links for admin listings
  ############################################################################
  
  def article_action_links( article )
    
    available_actions = []

    case current_user.role.downcase.to_sym
    when :writer
      if article.status == Article::Status[:unsubmitted]
        available_actions << :edit
        available_actions << :destroy if article.user_id==current_user.id
      end
    when :editor
      if [ Article::Status[:unsubmitted], 
           Article::Status[:editing] 
         ].include?(article.status)
          available_actions << :edit
          available_actions << :destroy
      end
    when :subeditor
      available_actions << :download
      if [ Article::Status[:unsubmitted], 
           Article::Status[:editing],
           Article::Status[:subediting] 
         ].include?(article.status)
          available_actions << :edit
          available_actions << :destroy
      end
    when :publisher, :admin
      available_actions << :download
      available_actions << :edit
      available_actions << :destroy
      if article.live?
        available_actions << :unpublish
      end
    end
    
    output = ""
    
    # Include locking support
    if available_actions.include? :edit
      if article.locked? && (article.lock.user != current_user)
        output << link_to( "Edit article",  
          edit_admin_article_path(article),
          :title=>"Edit article",
          :class=>"article_edit locked",
          :confirm => "This article is currently being edited by #{article.lock.user.email} as of #{article.lock.updated_at.strftime("%H:%M")}.\n\n"+
          "You may overwrite changes or lose your data if you continue to edit this article.\n\nDo you want to override the lock and open the article for editing?"
        )
      else
        output << link_to( "Edit article",  
          edit_admin_article_path(article),
          :title=>"Edit article",
          :class=>"article_edit"
        )
      end
    end
           
      
    output << link_to( "Show article",           
      admin_article_path(article),                    
      :title=>"Show article",           
      :class=>:article_show)  if available_actions.include? :download
      
    output << link_to( "Print article",          
      print_admin_article_path(article),              
      :title=>"Print article",
      :class=>:article_print)  if available_actions.include? :download
      
    output << link_to( "Download for InDesign",  
      admin_article_path(article, :format=>:indtt),  
      :title=>"Download for InDesign",  
      :class=>:article_indesign)  if available_actions.include? :download
      
    output << link_to("Unpublish article",      
      unpublish_admin_article_path(article),          
      :title=>"Unpublish article", :method => :post,
      :class=>:article_unpublish) if available_actions.include? :unpublish
      
    output << link_to("Obliterate article",     
      admin_article_path(article), 
      :method=>:delete,  
      :confirm => "Are you sure? If you obliterate this article, it will be removed and will not be recoverable.",
      :title=>"Obliterate article",     
      :class=>:article_destroy)   if available_actions.include? :destroy
    
    return output.html_safe
  end
  
  
  def article_next_stage_name( article )
    case article.status
    when Article::Status[:unsubmitted]
      text = "Submit to editors"
    when Article::Status[:editing]
      text = "Submit to subeditors"
    when Article::Status[:subediting]
      text = "Submit to publishing"
    when Article::Status[:published]
      text = "Publish now"
    when Article::Status[:ready]
      text = "Publish now"
    else
      return nil
    end
    return text
  end
  
  
  
  
  # Indesign helpers
  ############################################################################
  
  def indesign_header
    "<UNICODE-MAC>\n".html_safe +
    "<Version:5><FeatureSet:InDesign-Roman>".html_safe
  end
  
  def indesign_format(text, paratype, texttype)
    return "" if text.blank?
    return "<ParaStyle:#{paratype}>" + 
    text.gsub("<em>", "<CharStyle:Story formatting\\:#{texttype} Italic>").
    gsub("<i>", "<CharStyle:Story formatting\\:#{texttype} Italic>").
    gsub("</em>", "<CharStyle:>").
    gsub("</i>", "<CharStyle:>").
    gsub("<strong>", "<CharStyle:Story formatting\\:#{texttype} Bold>").
    gsub("</strong>", "<CharStyle:>").
    gsub("<b>", "<CharStyle:Story formatting\\:#{texttype} Bold>").
    gsub("</b>", "<CharStyle:>").html_safe
  end
  
  def simple_indesign_format(text, paratype, texttype=nil, firstpara=nil)
    return "" if text.blank?
    string = text.
    gsub("<em>", "<CharStyle:Italic>").
    gsub("<i>", "<CharStyle:Italic>").
    gsub("</em>", "<CharStyle:>").
    gsub("</i>", "<CharStyle:>").
    gsub("<strong>", "<CharStyle:Bold>").
    gsub("</strong>", "<CharStyle:>").
    gsub("<b>", "<CharStyle:Bold>").
    gsub("</b>", "<CharStyle:>").html_safe

		out_string = ""
		
		out_string << (firstpara ? "<ParaStyle:#{firstpara}>" : "<ParaStyle:#{paratype}>")
    out_string << "<CharStyle:#{texttype}>" if texttype
		out_string << string.gsub(/\n+/, "<ParaStyle:#{paratype}>")
    out_string << "<CharStyle:>" if texttype

    return out_string

  end
  
  # Work out review stars
  def indesign_review_stars( article )
    if article.review? && (article.review_rating.to_i > 0)
      text = "<ParaStyle:Reviews\\:Review Rating>"
      text << (0..article.review_rating.to_i-1).collect{|n| "r"}.join
      return text.html_safe
    else
      return ""
    end
  end
  
  def indesign_filtered_content( string )
    return "" if string.blank?
    allowed_tags = ["i", "em", "b", "strong"]
    string.to_s.gsub("<br />", "\n").strip_html_except(allowed_tags).html_safe
  end
  
  def indesign_with_newline( string )
    out = string.blank? ? "" : string + "\n"
    out.html_safe
  end
  
  # Form helpers
  ############################################################################
  
  def article_type_options( selected = nil )
    out = ("<option></option>" +
    Braincube::Config::ArticleTypes.map{|k,v| [v,k] }.sort{|a,b| a.first<=>b.first }.map do |type|
      content_tag(:option, type.first, :value => type.last, :selected => ("selected" if !selected.blank? && type.last==selected.to_sym) )
    end.join).html_safe
  end
  
  
  def publication_options(selected = nil)
    out = ("<option value=\"\">Web-only</option>" +
    @all_publications.map do |key, value|
      options = value.map{|v|
        content_tag(:option, v.name, :value => v.id, :selected => ( v==selected || (selected.nil? && key != :past && v==value.first) ) )
      }.join.html_safe
      content_tag(:optgroup, options, :label => ( key==:past ? "Past publications" : "Future publications") )
    end.join).html_safe
  end
  
  def section_options_for_list(selected=nil)
    out = @all_sections.map do |section|
      content_tag( 
        :option, 
        section.name, 
        :value => url_for( 
          :section_id => section.id, 
          :publication_id => params[:publication_id],
          :q => params[:q]
        ), 
        :selected => ( section.id == params[:section_id].to_i )
      )
    end
    out = out.unshift(
      content_tag( :option, "--All sections--", :value => url_for(:section_id=>nil, :publication_id => params[:publication_id], :q => params[:q]) )
    )
    out.join.html_safe
  end
  
  def publication_options_for_list(selected = nil)
    out = @all_publications.map do |key, value|
      options = value.sort{|a,b| b.date_street<=>a.date_street}.map{|v|
        content_tag( 
          :option, 
          v.name, 
          :value => url_for(
            :publication_id => v.id, 
            :section_id => params[:section_id],
            :q => params[:q]
          ), 
          :selected => ( v.id == params[:publication_id].to_i ) 
        )
      }.join.html_safe
      content_tag( :optgroup, options, :label => (key==:past ? "Past publications" : "Future publications"))
    end.sort
    out = out.unshift(
      content_tag( 
        :option, 
        "--All publications--", 
        :value => url_for(:publication_id=>nil, :section_id => params[:section_id], :q => params[:q])
      )
    )
    out.join.html_safe
  end
  
end
