//////////////////////////////////////////////////////////////////////////////
// Braincube: venues.js
// 
// Setup venue manager page - the map locator in particular
//////////////////////////////////////////////////////////////////////////////

braincube.admin.venues = {
	
	// Store the current location of the venue as a google maps Marker
	venue_marker: null,
	map_active: null,
	
	// Start the ball rolling
	init: function(){
		
		this.init_map();
		this.attachment.init();

	},
	
	init_map: function(){
		
		// Do nothing unless there's a map area on the page
		if( $("#map_area").length===0 ){ return; }
		this.load_google_maps();
		
	},
	
	// Load the google maps API - there's a map on the page. Once it's loaded,
	// execute a callback to handle our setup. This relies on the basic google
	// loader API being included, which it is by default.
	load_google_maps: function(){
		google.load("maps", "2", {"callback" : braincube.admin.venues.prep_map});
	},
	 
	// This prepares to show the map by calling the actual setup function when
	// the form tab containing the map is shown - otherwise,
	// the size and centering gets all messed up.
	prep_map: function(){
		var tabs_api = $(".tabbed_fieldsets ul.tabs").data("tabs");
		tabs_api.onClick(function(a,b){
			if( b===1 && !braincube.admin.venues.map_active ){
				braincube.admin.venues.set_initial_map_location();
				braincube.admin.venues.map_active = true;
			}
		});
	},
	
	// Onl called on initial display of the map
	set_initial_map_location: function(){
			
		var has_marker = false;
		
		// The latitude and longitude to display initially are stored in a
		// hidden element. Load them up into an object.
		var initial_location = {
			latitude: $("#braincube_default_map_location").html().split(",")[0],
			longitude: $("#braincube_default_map_location").html().split(",")[1],
			depth: 5
		};
			
		// If there is a value in the location fields for the venue, then set
		// that as the initial location and store that we have a marker available.
		if( !($("#latitude").val()==="") ){
			initial_location =  {
				latitude: $("#latitude").val(),
				longitude: $("#longitude").val(),
				depth: 15
			};
			has_marker = true;			
		}
	
		// Initialise the map with the initial location we calculated
		$("#map_area").googleMaps( initial_location );
	
	
		// If there are no markers, then we have to set things up so an initial 
		// click will create one. Otherwise, we just add the marker and setup
		// the drag events.
		if( !has_marker ){
					
			// Add an event listener to the map to intercept the click event and 
			// set the marker location. Also update the form fields.
			event_listener = GEvent.addListener($.googleMaps.gMap, "click", function(overlay, latlng) {
			  
				braincube.admin.venues.set_marker_location( latlng.lat(), latlng.lng() );
				braincube.admin.venues.update_venue_location_fields( latlng.lat(), latlng.lng() );
				
				// Remove the click event listener now that we've added a marker.
				GEvent.removeListener(event_listener);
				
			});
		
		} else {
			
			// There is already a location, so set the marker.
			braincube.admin.venues.set_marker_location( 
				initial_location.latitude, initial_location.longitude
			);

		}
	
		// Add change handlers to venue form fields
		$("#latitude,#longitude").keyup(function(){
			braincube.admin.venues.set_marker_location(
				$("#latitude").val(), $("#longitude").val()
			);
		});
		
		// Setup auto-locate button
		$("#venue_auto_locate_button").click(function(){
			
			// Check that the postcode has been filled out
			if( $("#venue_postcode").val().length===0 ){
				alert("You need to enter a postcode on the information page to auto-locate the venue.");				
				return false;
			}
			
			// Add a loading gif
			$(this).addClass("loading");
			
			// Geocode the supplied postcode and pass the result to a callback
			// to either update the location or error out.
			geocoder = new GClientGeocoder();
			geocoder.getLocations( 
				($("#venue_postcode").val() + ", UK"), 
				function(response){ 
					braincube.admin.venues.update_from_geocode( response );
					$("#venue_auto_locate_button").removeClass("loading");
				}
			);
			return false;
			
		});
		
	},
	
	// Sets the marker location on the map to the supplied co-ordinates.
	set_marker_location: function( lat, lng ){
		
		if( this.venue_marker ){
			
			// If there is already a marker, then just set the location of it
			this.venue_marker.setLatLng( new GLatLng(lat, lng) );
			
		} else {
			
			// There is no marker available, so create one and add it to the map
			marker = new GMarker( new GLatLng(lat, lng), {draggable: true} );
			this.venue_marker = marker;
			$.googleMaps.gMap.addOverlay(marker);
			
			// Add a drag handler to the marker. When it's moved, update the 
			// corresponding location fields in the venue form.
			GEvent.addListener(marker, "dragend", function( newlatlng ) { 
				braincube.admin.venues.update_venue_location_fields(
					newlatlng.lat(), newlatlng.lng()
				); 
			});
			
		}
		
		// Center on the marker
		this.center_map_on_marker();
		
	},
	
	// Just update the fields in the venue form with the supplied location
	update_venue_location_fields: function( lat, lng ){
		$("#latitude").val( lat );
		$("#longitude").val( lng );
		this.center_map_on_marker();
	},
	
	// Update the map and location fields when a callback is fired by the geocoder
	update_from_geocode: function( response ){
		
		// Check if the response was OK
		if( response.Status && response.Status.code === 200 ){
			
			var loc = response.Placemark[0].Point.coordinates;
			this.update_venue_location_fields( loc[1], loc[0] );
			this.set_marker_location( loc[1], loc[0] );
			
		} else {
			
			alert("Postcode not found. Please double-check or enter the location manually.");
			
		}
		
	},
	
	// Moves the map so it is centered on the venue marker.
	center_map_on_marker: function( ){
		if( this.venue_marker==null ){ return };
		$.googleMaps.gMap.setCenter( this.venue_marker.getLatLng() );
	},
	
	
	// Attachment
	
	attachment: {
		
		loading: false,
		
		init: function(){
			
			// Do nothing unless there's an venue attachment box
			if( $("#venue_search").length===0){ return; }
			
			// Hook into the search box for ajax
			var _this = this;
			$("#venue_search").keyup(function(){
				$("#venue_search_spinner").show();
				clearTimeout( _this.loading );
				_this.loading = setTimeout( _this.execute, 300 );
			});

			// Monitor the add links
			$(".venue_search_add_link").live("click", function(){
				_this.add_venue( $(this) );
				return false;
			});

			// Monitor the remove links
			$(".venue_search_remove_link").live("click", function(){
				_this.remove_venue($(this));
				return false;
			});
			
			// Hide the spinner
			$("#venue_search_spinner").hide();
			
		},
		
		// Run the remote search for attachments
		execute: function(){
			$.get("/admin/venues/for_attachment?q=" + $("#venue_search").val(), function(html){
				$("#venue_search_results").html(html);
				$("#venue_search_spinner").hide();
			});
		},
		
		// Add the venue to the associated venue list
		add_venue: function(link){
			
			// Get the id of the venue to add
			id = link.attr("id").split("_")[3];
			
			// Display a loading message
			link.html("Loading...");
			
			// Get the list of IDs
			values = $("#associated_venue_ids").val().split(",");
			if( values[0]==="" ){ values=[]; }
			
			// Add this ID to the list
			values = values.concat([id]);
			$("#associated_venue_ids").val( values.unique().join(",") );
			
			this.reload_venue_list(link);
		},
		
		reload_venue_list: function(link){
			
			// Show the spinner while we load
			$("#venue_search_spinner").show();
			
			// Request the list
			$.get("/admin/venues/for_attachment?ids=" + $("#associated_venue_ids").val(), function(html){
				
				$("#venue_search_spinner").hide();
				link.parents("li").hide("blind");
				$("#associated_venue_list").html(html);
				
			});
		
		},
		
		remove_venue: function(link){
			
			// Get the id of the venue to remove
			id = link.attr("id").split("_")[3];
			
			// Display a loading message
			link.html("Loading...");
			
			// Get the list of IDs
			values = $("#associated_venue_ids").val().split(",");
			
			values[ values.indexOf(id)] = 0;
			$("#associated_venue_ids").val( $.map(values, function(v){ if(v>0){ return v; }}).unique().join(",") );
			
			this.reload_venue_list(link);
			
		}
		
	}

	
	
};