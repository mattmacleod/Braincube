module Admin::EventsHelper
	
	
	def event_featured( event )
		link_to (event.featured? ? "Yes" : "No"), "#", :"data-event-id" => event.id, :class => "#{(event.featured ? :tick : :cross)} event_featured_toggle"
	end
	
	############################################################################
	# Indesign helpers
	############################################################################
	
	
	# Categorised by date...
	def indesign_listings_date( thedate )
		"<ParaStyle:Listings\:Date title>#{ thedate.strftime("%a %d %b")}"
	end
	
	def indesign_listings_title( performance )
		"<ParaStyle:Listings\:Event Title>#{ performance.get_title }".html_safe
	end
	
	def indesign_listings_data( performance )
		
		out = "<ParaStyle:Listings\:Event><CharStyle:Listings\:Event Venue>"
		
		out << performance.venue.title
		
		out << "<CharStyle:>, "
		out << "<CharStyle:Listings\:Event Time>"
		
		if performance.starts_at && performance.ends_at
			out << (performance.starts_at.strftime("%H:%M") + "–" + performance.ends_at.strftime("%H:%M"))
		else
			out << "from #{performance.starts_at.strftime("%H:%M")}"
		end
		
		out << "<CharStyle:><CharStyle:Listings\:Event Time>"
		if performance.price.to_s.length > 0
			out << ", #{ indesign_price_format performance.price }"
		end
		
		out << "<CharStyle:>"
		
		return out
	end
	
	def indesign_listings_description( performance )
		"<ParaStyle:Listings\:Event Description>#{performance.get_description.to_s.gsub("\r\n\r\n", "\r\n")}"
	end
	
	def indesign_price_format( price )
    return price unless numeric?( price )
    return "free" if (price.to_f==0.to_f)
    ("£%01.2f" % ((Float(price.to_f) * (10 ** 2)).round.to_f / 10 ** 2)).gsub(".00", "")
  end
	
	
	
	
	# Categorised by venue	
	
	def indesign_listings_event_title( event )
		"<ParaStyle:Listings\:Event Title>#{ event.title }".html_safe
	end
	
	def indesign_listings_venue( venue )
		"<ParaStyle:Listings\:Date title>#{ venue }"
	end
	
	def indesign_listings_event_data( event )
		out = "<ParaStyle:Listings\:Event><CharStyle:Listings\:Event Time>"
		out << "#{event.date_string(:all)}, #{event.time_string}, #{event.price_string}"
		out << "<CharStyle:>"
	end
	
	def indesign_listings_event_description( event )
		out = "<ParaStyle:Listings\:Event Description>"
		out << HTMLEntities.new.decode( event.content.to_s.gsub("\r\n\r\n", "\r\n").to_s.gsub(/<!--(.*?)-->[\n]?/m, '').gsub(/<\/?[^>]*>/, "").gsub(/<!--(.*?)-->[\n]?/m, '').gsub("&nbsp;", " ")).rstrip
	end
	


end
