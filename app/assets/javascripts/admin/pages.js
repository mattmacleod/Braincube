//////////////////////////////////////////////////////////////////////////////
// Braincube: pages.js
// 
// Handles the page tree manager
//////////////////////////////////////////////////////////////////////////////

braincube.admin.pages = {
	
	init: function(){
		
		// Setup the trees
		this.tree_browser.init();
		
		// Setup the page type tabs
		this.setup_page_type_tabs();
		
		// Setup the UI js to handle title and URL generation
		this.setup_fields();
		
		// Setup the widget manager
		this.widget_manager.init();
		
	},
	
	tree_browser: {
		
		init: function(){
			
			// Return unless we've got page trees
			if($("#page_tree").length===0){ return; }
			
			// Setup the JStree
			this.setup_tree();
			
			// Setup new child links
			this.setup_new_child_links();
			
			// Setup search handler
			// Watch the search field for updates and submit search
			$("#pages_search_field").keyup(function(){

				clearTimeout(this.timer);
				$("#search_spinner").show();

				// Submit the search after a short delay (i.e. only submit a search a
				// short while after the user has stopped typing)
				this.timer = setTimeout(braincube.admin.pages.tree_browser.do_search, braincube.admin.jsconfig.paginated_search_timeout);
				
			});
						
		},
		
		setup_tree: function(){
			
			// Execute jstree
			$("#page_tree").jstree({
				plugins : [ "html_data", "search", "dnd", "crrm" ],
				core: {
					animation: 50
				},
				search: {
					case_insensitive: true
				},
				dnd: {
					copy_modifier: null
				},
				crrm: {
					move: {
						check_move: function(data){
							return braincube.admin.pages.tree_browser.validate_move( data );
						}
					}
				}
			});
			
			// Setup drag events
			_this = this;			
			$("#page_tree").bind("move_node.jstree", _this.handle_reorder);
			
			// Highlights
			$("#page_tree a.highlighted").effect("highlight", {}, 5000);
			
		},
		
		setup_new_child_links: function(){
			$("#page_tree li a:not(.add_child)").hover(
				function(){ 
					$(this).siblings(".add_child").addClass("show");
				},
				function(){ 
					$(this).siblings(".add_child").removeClass("show");
				}
			);
		},
		
		// Check that the move is valid
		validate_move: function( move ){
			return move.np[0].id !== "page_tree";
		},
		
		
		// The handler for actually submitting a search from the search box
		do_search: function(){
						
			// Hide the spinner
			$("#search_spinner").hide();
			
			// Actually do the search
			$("#page_tree").jstree( "search", $("#pages_search_field").val() );
			
			// If we're searching for an empty string, then remove the search
			// class, otherwise add it...
			if( $("#pages_search_field").val()==="" ){
				$("#page_tree").removeClass("searching");
			} else {
				$("#page_tree").addClass("searching");
			}
			
		},
		
		handle_reorder: function(d,e){
			
			// Get the essential details
			var moving_id = e.args[0].o.attr("id").replace("page_node_", "");
			var parent_id = e.args[0].np.attr("id").replace("page_node_", "");
			var cp = e.args[0].cp;
			
			// Calculate ordering
			var order_array = [];
			$("#page_list_wrapper li").each( function(){ 
				order_array.push( $(this).attr("id").replace("page_node_", "") );
			});
			
			
			$("#page_tree").hide("blind");
			$("#page_tree_loading").show("blind");
			
			
			// Send the attributes
			$.ajax( 
				{	
					url: "/admin/pages/update_order", 
					type: "POST",
					data: { m: moving_id, p: parent_id, s: order_array },
					complete: function(e,f){
						$("#page_list_wrapper").html( e.responseText );
						braincube.admin.pages.tree_browser.setup_tree();
						$("#page_tree").show("blind");
						$("#page_tree_loading").hide("blind");
						if( f==="error" ){							
							alert("Error updating page structure.");
						}
						
					}
				}
			);	
			
		}
		
	},
	
	setup_fields: function(){
		
		// Return unless there's a page URL
		if( $("#page_url").length==0 ){ return; }

		// Setup the title updater
		$("#page_title").keyup( 
			function(){
				text = "Page: " + $(this).val();
				if(text.length===0){ text = "Page: (untitled)"; }
				$("h1").html(text);
		}).keyup();
		
		// Setup the URL generator
		url_element = $("#page_url");
		
		$("#page_parent_id").live("change", function(){
			if( url_element.data("active")==true ){
				 braincube.admin.pages.update_page_url();
			}
		});
		
		$("#page_title").live("keyup", function(){
			if( url_element.data("active")==true ){
				 braincube.admin.pages.update_page_url();
			}
		});
		
		// Set the focus event to check and enable
		$("#page_title,#page_parent_id").focus(function(){
			if( url_element.val().length == 0 ){
				url_element.data("active", true);
			}
		});
		
		// Set the blur event to disable any further updates if there is any content
		$("#page_title,#page_parent_id").blur(function(){
			if( url_element.val().length > 0 ){
				url_element.data("active", false);
			}
		});
		
	},
	
	update_page_url: function(){
		if( !$("#page_url").data("active")==true ){ return; }
		if( ($("#page_title").val()==="") || ($("#page_parent_id").val()==="" )){ 
			$("#page_url").val("") 
		} else {
			$("#page_url").val( ($("#page_parent_id").find("option:selected").data("path") + "/" + this.urlify( $("#page_title").val() )).replace(/^\//, "") )
		}
	},
	
	urlify: function( value ){
		value = value.toLowerCase();
		value = value.replace(/(\s+(and|or|the|go|at|be|to|as|at|is|it|an|of|on|a)\s+)+/g, " ");
		value = value.replace(/[^a-z0-9_\-\s]/g, "");
		value = value.replace(/\s+/g, "_");
		value = value.replace(/\_+/g, "_");
		return value;
	},
	
	setup_page_type_tabs: function(){
		
		// Return unless needed
		if( $(".page_forms").length===0 ){ return; }
		
		// Setup handlers on the type drop-down
		$("#page_page_type").change(this.update_page_type_tabs).change();
		
	},
	
	update_page_type_tabs: function(){
		
		// Hide all tabs
		$(".type").hide();
		
		// Show selected tab
		$("#page_type_" + $("#page_page_type").val() + "_tab").show();
		
		
	},
	
	
	widget_manager: {
		
		init: function(){
			
			var _this = this;
			
			// Quit if there are no widget forms
			if($(".page_widget_items").length===0){ return; }
			
			// Setup ordering
			this.setup_ordering();
			
			// Setup clear button
			$(".page_widget_tools a.delete").click( this.clear_widgets );
			
			// Setup add button
			$(".page_widget_tools a.new").click( this.add_widget );
			
			// Setup delete buttons
			$(".page_widget_items .delete_widget").live("click", function(){ _this.remove_widget( $(this).parents(".widget") ); return false; });
			
		},

		setup_ordering: function(){

			// Create the sortable
			$(".page_widget_list").sortable({
				axis: "y", 
				opacity: 0.5,
				placeholder: "placeholder",
				forcePlaceholderSize: true,
				stop: function(event,ui){
					braincube.admin.pages.widget_manager.set_sort_order();
				}
			});

			// Setup initial sort order fields
			this.set_sort_order();

		},

		set_sort_order: function(){
			var idx = 0;
			$(".page_widget_list").find("input.sort_order").each(function(){
				$(this).val( idx++ );
			});
		},

		clear_widgets: function(){
			if( $(this).parents("widget_slot").find(".page_widget_items .widget:visible").length>0 ){
				$(this).parents("widget_slot").find(".page_widget_items .delete_widget").click();
				$(this).parents("widget_slot").find(".page_widget_items .empty").show("blind");
			}
			return false;
		},

		add_widget: function(){

			var slot = $(this).data("slot");
			var string = eval("global_page_widget_string_"+slot);
			
			$(this).parents(".widget_slot").find(".page_widget_items .empty").hide();

			new_id = new Date().getTime();
	
			$(this).parents(".widget_slot").find('.page_widget_list').append( string.replace(/\[\d\]/g, "["+new_id+"]").replace(/\_\d\_/g, "_"+new_id+"_") );
			braincube.admin.pages.widget_manager.set_sort_order();

			return false;
			
		},
		
		remove_widget: function( element ){
			
			// If this is an existing element, we have to set the destroy field.
			// Otherwise, we can just remove the whole thing and it'll be fine.
			if( element.hasClass("existing") ){
				element.find(".destroy_field").val(1);
				element.hide("blind");
			} else {
				element.hide("blind");
				element.remove();
			}
			
			// Are there any attachments left?
			if( $(this).parents(".widget_slot").find(".page_widget_items input.destroy_field[value=false]").length===0 ){
				$(this).parents(".widget_slot").find(".page_widget_items .empty").show("blind");
			}
			
			return false;
			
		}
				
	}
	
};