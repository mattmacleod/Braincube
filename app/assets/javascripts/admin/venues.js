//////////////////////////////////////////////////////////////////////////////
// Braincube: venues.js
// 
// Setup venue manager page - the map locator in particular
//////////////////////////////////////////////////////////////////////////////

braincube.admin.venues = {
	
	map             : null,
	geocoder        : null,
	marker          : null,
	initial_marker  : true,

	config : {
		latitude_field : "latitude",
		longitude_field: "longitude",
		lat            : 56.909002,
		lng            : -4.284668,
		map_id         : "map_area",
		zoom           : 5,
		location_zoom  : 16
	},
	
	// Start the ball rolling
	init: function(){
		
		this.attachment.init();

	},
	
	init_map: function(){
		
		// Do nothing unless there's a map area on the page
		if( $("#map_area").length===0 ){ return; }
		this.load();
		
	},

	// The first stage in loading - bind to the window load event.
	load: function() {
		window.addEventListener('load', this.actual_load, false);

		// Hide location button if no field registered for autolocation
		$autolocation_data_field = $("#venue_postcode");

		$("#venue_auto_locate_button").click( function() {
	 	   braincube.admin.venues.find_address($autolocation_data_field.val() + ", UK");
		   return false;
		});

	},

	// When the window has fired the load event, add the Google Maps API script
	actual_load: function(){
		var script  = document.createElement("script");
		script.type = "text/javascript";
		script.src  = "http://maps.googleapis.com/maps/api/js?sensor=false&callback=braincube.admin.venues.initialize";
		document.body.appendChild(script);
	},
	
	// Called when the Google Maps API script has loaded
	initialize: function(){


		// Set the initial zoom, center and view of the map
		var mapOptions = {
			zoom     : braincube.admin.venues.config.zoom,
			center   : new google.maps.LatLng( braincube.admin.venues.config.lat, braincube.admin.venues.config.lng),
			mapTypeId: google.maps.MapTypeId.ROADMAP
		}
		
		// Create the map in the configured element
		this.map      = new google.maps.Map( document.getElementById(braincube.admin.venues.config.map_id), mapOptions );
		this.geocoder = new google.maps.Geocoder();

		if( this.initial_marker ){

			// If we are to initially load a marker, then create one
			this.marker = new google.maps.Marker({
				map      : this.map, 
				position : mapOptions.center, 
				draggable: true
			});

			// Allow the marker to be moved
			this.setup_marker_listeners();

		} else {

			// We are not initially loading a marker, so add a click 
			// event handler to insert one when the map is clicked

			var listener = google.maps.event.addListener(this.map, "click", function(e) {


				braincube.admin.venues.marker = new google.maps.Marker({
				 	position: e.latLng,
					map: braincube.admin.venues.map,
					draggable: true
				});

				braincube.admin.venues.update_location_from_marker( braincube.admin.venues.marker );
				braincube.admin.venues.setup_marker_listeners();
				
				google.maps.event.removeListener(listener);

			});

		}

		var tabs_api = $(".tabbed_fieldsets ul.tabs").data("tabs");
		tabs_api.onClick(function(a,b){
			if( b===1 ){
				google.maps.event.trigger( braincube.admin.venues.map, 'resize' );
				braincube.admin.venues.map.setCenter( 
					new google.maps.LatLng( 
						braincube.admin.venues.config.lat, 
						braincube.admin.venues.config.lng
					)
				)
			}
		});
		
	},
	
	// Allow a marker to be dragged to a new position
	setup_marker_listeners : function(){
		google.maps.event.addListener(braincube.admin.venues.marker, "dragend", function(){
			braincube.admin.venues.update_location_from_marker( braincube.admin.venues.marker );
		});
	},
	
	// Given an address, find a postcode and move the marker
	find_address: function(address) {

		this.geocoder.geocode(

			{ address: address },

			function(results, status) {
				
				if (status == google.maps.GeocoderStatus.OK) {
					braincube.admin.venues.map.setCenter(results[0].geometry.location);
					braincube.admin.venues.update_marker_location( results[0].geometry.location);
				} else {
					alert(address + "not found on map. \n Geocode was not successful for the following reason: " + status);
				}
			}
		);

	},
	
	
	update_marker_location: function(LatLng) {

		if( this.marker === null ){

			this.marker = new google.maps.Marker({
			 	position: LatLng,
				map: this.map
			});

			this.setup_marker_listeners();

		} else {

			this.marker.setPosition(LatLng);

		}

		this.map.setCenter(LatLng)
		this.map.setZoom(this.config.location_zoom);
		this.update_location_from_marker( this.marker );

	},
	
	
	update_location_from_marker: function(marker) {
		var lat = marker.getPosition().lat();
		var lng = marker.getPosition().lng();
		
		$("#"+this.config.latitude_field).val( lat );
		$("#"+this.config.longitude_field).val( lng );
		
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