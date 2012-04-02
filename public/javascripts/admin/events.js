//////////////////////////////////////////////////////////////////////////////
// Braincube: events.js
// 
// Handles the events, performances etc.
//////////////////////////////////////////////////////////////////////////////

braincube.admin.events = {
	
	// Setup the asset manager
	init: function(){
		this.setup_accordion();								// Setup the accordian table rows
		this.performance_generator.init();		// Performance generation stuff
		this.attachment.init();	
		this.setup_venue_selector();
		this.setup_event_featured_toggle();
	},
	
	// Setup accordion table rows on the event form. Also delete buttons.
	setup_accordion: function(){
		
		// Return if there is no event performance list
		if($(".event_performance_items").length===0){ return; }
		
		var _this = this;
		
		// Open the sibling row when edit button is clicked
		$(".event_performance_items td.icons .edit").live("click",  function(){
			$(this).parents("tr").next().show();
			$(this).hide();
			return false;
		});
		
		// Remove item when remove button clicked
		$(".event_performance_items td.icons .remove").live("click", function(){ 
			_this.remove_performance( $(this).parents("tr") ); 
			return false; 
		});
		
		// Hide details links
		$(".event_performance_items h3 a").live("click", function(){ 
			$(this).parents("tr").hide();
			$(this).parents("tr").prev().find(".icons a").show();
			return false; 
		});
		
		// Clear buttons
		$(".event_performance_tools a.delete_all").click( _this.clear_all_performances );
		$(".event_performance_tools a.delete_old").click( _this.clear_old_performances );

		// Add performance button
		$(".event_performance_tools a.new").click( this.open_performance_builder );
		
	},
	
	setup_venue_selector: function(){
		$(".venue_selector").chosen();
	},
		
	// Remove a specific performance by the first TR element
	remove_performance: function( element ){
		
		var sibling = element.next();
				
		// If this is an existing element, we have to set the destroy field.
		// Otherwise, we can just remove the whole thing and it'll be fine.
		if( element.hasClass("existing") ){
			sibling.find(".destroy_field").val(1);
			element.hide();
			sibling.hide();
		} else {
			element.remove();
			sibling.remove();
		}
		
		// Are there any attachments left?
		if( $(".event_performance_items input.destroy_field[value=false]").length===0 ){
			$(".event_performance_items .empty").show();
			$(".event_performance_items table").hide();
		}
		
		return false;
		
	},
	
	// Removes all performances
	clear_all_performances: function(){
		$(".event_performance_items tr.summary a.remove").click();
		return false;
	},
	
	// Removes old performances
	clear_old_performances: function(){
		$(".event_performance_items tr.summary.expired a.remove").click();
		return false;
	},
	
	open_performance_builder: function(){
		$.prettyPhoto.open("/admin/events/build_performances&iframe=true&width=850&height=" + (document.documentElement.clientHeight - 100));
		return false;			
	},
	
	// Generator code
	performance_generator: {
		
		init: function(){
			
			// Return unless nothing doing
			if( $(".build_performances_window").length===0 ){ return; }
						
			// Setup a click action on the radio buttons
			$(".performance_type_buttons input").click( this.update_performance_type_panels );
			
			// Hide all of the panels
			$(".performance_types .one_off, .performance_types .periodic, .performance_types .opening_times, .performance_types .periodic_opening_times").hide();
			
			// Setup the initial selection
			$(".performance_type_buttons input:checked").click();
			
			// Setup the preview link
			$(".build_performances_window a.preview_link").click( this.load_preview );
			
			// Setup the venue AJAX
			$("#performance_run_performance_attributes_venue_id").change( this.load_venue_opening_times );
      
		},
		
		update_performance_type_panels: function(){
			
			// Hide all of the panels
			$(".performance_types .one_off, .performance_types .periodic, .performance_types .opening_times, .performance_types .periodic_opening_times").hide();
			
			// One-off
			if( $("#performance_run_run_type_one_off:checked").length > 0 ){ $(".performance_types .one_off").show(); }
			
			// Periodic
			if( $("#performance_run_run_type_periodic:checked").length > 0 ){ $(".performance_types .periodic, .performance_types .periodic_opening_times").show(); }
			
			// Opening times
			if( $("#performance_run_run_type_opening_times:checked").length > 0 ){ $(".performance_types .opening_times, .performance_types .periodic_opening_times").show(); }
			
			
		},
		
		load_preview: function(){
		  $("#performance_preview_wrapper").html("Please wait, loading details...")
			$(this).parents("form").submit();
		},
		
		// Save an array of new performance objects
		save_performances: function( arr ){
			
			// Get the current index of performance items
			current_index = ($(".performance_list_contents tr").length / 2);
			
			// Replace the generated index in the supplied items
			for( i=0; i<arr.length; i++){
				
				// Replace the index
				var content = arr[i].replace(new RegExp( ("event_performances_attributes_"+i), 'g'), ("event_performances_attributes_"+(i + current_index)));
				content = content.replace(new RegExp( ("event\\[performances_attributes\\]\\["+i), "g"), ("event[performances_attributes]["+(i + current_index)));
				
				// Append to the performance table
				$('.performance_list_contents').append( content );
				
			}
		
			// Show the performance table and hide the empty warning
			$(".event_performance_items .empty").hide();
			$(".event_performance_items table").show();
		},
		
		load_venue_opening_times: function(){
			$.get("/admin/venues/" + $(this).val() + "/opening_times", function(html){
				$("#venue_opening_times").html(html);
			});
		}
		
	},
	
	attachment: {
		
		loading: false,
		
		init: function(){
			
			// Do nothing unless there's an event attachment box
			if( $("#event_search").length===0){ return; }
			
			// Hook into the search box for ajax
			var _this = this;
			$("#event_search").keyup(function(){
				$("#event_search_spinner").show();
				clearTimeout( _this.loading );
				_this.loading = setTimeout( _this.execute, 300 );
			});

			// Monitor the add links
			$(".event_search_add_link").live("click", function(){
				_this.add_event( $(this) );
				return false;
			});

			// Monitor the remove links
			$(".event_search_remove_link").live("click", function(){
				_this.remove_event($(this));
				return false;
			});
			
			// Hide the spinner
			$("#event_search_spinner").hide();
			
		},
		
		// Run the remote search for attachments
		execute: function(){
			$.get("/admin/events/for_attachment?q=" + $("#event_search").val(), function(html){
				$("#event_search_results").html(html);
				$("#event_search_spinner").hide();
			});
		},
		
		// Add the event to the associated event list
		add_event: function(link){
			
			// Get the id of the event to add
			id = link.attr("id").split("_")[3];
			
			// Display a loading message
			link.html("Loading...");
			
			// Get the list of IDs
			values = $("#associated_event_ids").val().split(",");
			if( values[0]==="" ){ values=[]; }
			
			// Add this ID to the list
			values = values.concat([id]);
			$("#associated_event_ids").val( values.unique().join(",") );
			
			this.reload_event_list(link);
		},
		
		reload_event_list: function(link){
			
			// Show the spinner while we load
			$("#event_search_spinner").show();
			
			// Request the list
			$.get("/admin/events/for_attachment?ids=" + $("#associated_event_ids").val(), function(html){
				
				$("#event_search_spinner").hide();
				link.parents("li").hide("blind");
				$("#associated_event_list").html(html);
				
			});
		
		},
		
		remove_event: function(link){
			
			// Get the id of the event to remove
			id = link.attr("id").split("_")[3];
			
			// Display a loading message
			link.html("Loading...");
			
			// Get the list of IDs
			values = $("#associated_event_ids").val().split(",");
			
			values[ values.indexOf(id)] = 0;
			$("#associated_event_ids").val( $.map(values, function(v){ if(v>0){ return v }}).unique().join(",") );
			
			this.reload_event_list(link);
			
		}
		
	},
	
	setup_event_featured_toggle: function(){
		
		$("a.event_featured_toggle").live("click", function(){
			
			var url = "/admin/events/" + $(this).data("event-id") + "/toggle_featured";
			
			var $this = $(this);
			
			$.get( url, function( data ){
				if( data=="true" ){
					$this.removeClass("cross").addClass("tick");
					$this.html("Yes");
				} else {
					$this.removeClass("tick").addClass("cross");
					$this.html("No");
				}
			} );
			
			return false;
			
		});
		
	}
	
	
};
