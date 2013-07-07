//////////////////////////////////////////////////////////////////////////////
// Braincube: articles.js
// 
// Handles the article manager pages - listings and forms
//////////////////////////////////////////////////////////////////////////////

braincube.admin.articles = {

	// Initialise the article manager JS
	init: function(){
		this.setup_publication_filter();			// Setup the publication filter
		this.setup_section_filter();					// Setup the section filter
		this.setup_article_type_chooser();		// Setup the article type widget
		this.setup_title_updater();						// Auto-update page title from form
		this.setup_show_links();							// Setup listings links to tools
		this.setup_auto_tagger();							// Setup listings links to tools
		this.lock_checker.init();							// Init the article lock checker
		this.drafts.init();										// Setup draft management
	},
	
	// Changes the location to the value of the select box when the publication
	// selector is changed on the listings page
	setup_publication_filter: function(){
		$("#publication_id").live( "change", function(){ window.location = $(this).val(); } );
	},
	
	// Changes the location to the value of the select box when the section
	// selector is changed on the listings page
	setup_section_filter: function(){
		$("#section_id").live( "change", function(){ window.location = $(this).val(); } );
	},

	// For the article form - hide the article type subforms, only displaying 
	// selected one and updating when the selector is changed
	setup_article_type_chooser: function(){
		
		// Hide all subforms
		$(".type_options fieldset").hide();
		
		$("#article_article_type").change(function(){
			// Hide all subforms and show only the selected one
			$(".type_options fieldset").hide();
			$(".type_options fieldset#article_type_" + $(this).val() ).show();
		}).change();
		
	},
	
	// Update the title of the article form page when the content of the title
	// field in the form is changed. Sets to a single non-breaking space if empty
	// and is called on first visiting the page.
	setup_title_updater: function(){
		$("#article_title").keyup( 
			function(){
				text = $(this).val();
				if(text.length===0){ text = "(untitled)"; }
				$("h1").html(text);
		}).keyup();
	},
	
	// For the listings pages - sets up the links to show articles in plain view
	// and in print view. Adds iframe to handle the latter.
	setup_show_links: function(){
		
		// Don't execute unless there's an article list.
		if( $(".search_form.articles").length===0 ){ return; }
		
		// Add the print iframe inside the body closing tag
		$("body").append("<iframe id='print_frame' name='print_frame' style='width: 0; height: 0;'></iframe>");
		
		// When the show button is clicked, just open in a new window
		$("a.article_show").live( "click", function() {
        $(this).attr("target", "_blank");
    });
		
		// When the print button is clicked, load the article into the new print
		// iframe. Then focus on it and print once it's loaded.
		$("a.article_print").live( "click", function() {
			
        $(this).attr("target", "print_frame");
			
				$("#print_frame").load( 
					function() {
						window.frames['print_frame'].focus();
						window.frames['print_frame'].print();
					}
				);
				
    });
		
	},
	
	
	// Sets up automatic tagging. Only runs once.
	setup_auto_tagger: function(){
		
		// First, check if there is an article loaded
		if( $("#article_tag_list").length===0 ){ return; }
		
		// Then return unless the tag list is empty
		if( $("#article_tag_list").val().length > 0 ){ return; }
		
		// The tag list is empty, so when we change the section or page type
		// dropdowns, rewrite the tag list. Once we've chosen both, disable
		// the event (so we don't overwrite subsequent tags)
		$("#article_section_id,#article_article_type").change( this.handle_article_or_section_change );
		
	},
	
	handle_article_or_section_change: function(){
		
		if( ($("#article_article_type option:selected").html().length > 0) && ($("#article_section_id option:selected").html().length > 0) ){
			
			// We've selected both, so remove this handler
			$(this).unbind("change", braincube.admin.articles.handle_article_or_section_change);
			
			$("#article_tag_list").val( 
				[$("#article_article_type option:selected").html(), $("#article_section_id option:selected").html()].join(", ")
			);
							
		} else if( $("#article_article_type option:selected").html().length > 0){
			
			$("#article_tag_list").val( 
				$("#article_article_type option:selected").html()
			);
			
		} else if( $("#article_section_id option:selected").html().length > 0){
			
			$("#article_tag_list").val( 
				$("#article_section_id option:selected").html()
			);
							
		} else {
			
			return;
			
		}
		
	},
	
	// This is the lock checker. Periodically calls the check_lock method on the
	// articles controller to see if anybody else is editing the article.
	lock_checker: {
		
		// Start the lock checker, periodically calling. Only run if there is an
		// article loaded
		init: function(){
			if( $("#current_article_id").length > 0 ){
				_this = this;
				setInterval(_this.execute, braincube.admin.jsconfig.lock_checker_frequency );
			}
		},
	
		// Execute a lock checker iteration - load the status from the server
		// and update the notification area. Disable autosaves unless the lock 
		// belongs to the current user.
		execute: function(){
			
			var lock_check_url = "/admin/articles/" + $("#current_article_id").val() + "/check_lock";
			
			$.ajax({
				url: lock_check_url, 
				method: "get",
				success: function( html ){
					$("#article_lock_info").html( html );
					braincube.admin.articles.drafts.enable_autosave_if_locked();
				},
				error: function(){
					$("#article_lock_info").html( "<div id=\"lock_warning\">Unable to contact server</div>" );
					$("#lock_warning").effect("pulsate");
				}
			});
			
		}
	},
	
	// Handle periodic and manual article draft saving. 
	drafts: {
		
		// Flag to indicate if we should autosave
		autosave_enabled: false,
		changed_since_last_draft: false,
		
		// Start the draft manager - attach the click event to the draft button
		// and set up a timer to automatically save drafts.
		init: function(){
			$("input.save_draft").click( this.save_draft );
			
			// Monitor all form fields in main body for change.
			_this = this;
			$("form.edit_article input, form.edit_article textarea, form.edit_article select").bind("change keyup", function(){
				braincube.admin.articles.drafts.changed_since_last_draft = true;
			});
			
			// Enable autosave
			this.enable_autosave_if_locked();
			
			// Set the timer for drafts
			setInterval( 
				this.save_draft_if_changed,
				braincube.admin.jsconfig.autosave_frequency
			);
			
		},
		
		// Save a draft only if this article has changed since the last draft
		save_draft_if_changed: function(){
			_this = braincube.admin.articles.drafts;
			if( _this.autosave_enabled && _this.changed_since_last_draft ){
				_this.save_draft();
			}
		},
		
		// Actually save a draft
		save_draft: function(){

			// Mark unchanged
			this.changed_since_last_draft = false;
			
			tinyMCE.triggerSave();

			// Set the button to indicate a draft is being saved
			$("input.save_draft").addClass("loading");
			$("input.save_draft").attr("value", "Saving draft...");
      tinyMCE.get('article_content').setProgressState(1);

			// Submit the form by Ajax
			$(".edit_article").ajaxSubmit({
				
				data: { commit: "Save draft" },
				
				// When the save is complete, remove the loading state from the save
				// button and reset the text after two seconds.
				complete: function(){
					$("input.save_draft").removeClass("loading");
					setTimeout("$(\"input.save_draft\").attr('value', 'Save draft')", 2000);
					tinyMCE.get('article_content').setProgressState(0);
				},
				
				// Update the text on the save button to indicate status.
				success: function(){
					$("input.save_draft").attr("value", "Saved!");
				},
				
				error: function(){
					$("input.save_draft").attr("value", "Failed!");
				}
				
			}); 

			return false;
		},
		
		enable_autosave_if_locked: function(){
			this.autosave_enabled = ( $("#lock_warning").length === 0 );
		}
		
	}

};