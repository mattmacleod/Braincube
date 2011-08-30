//////////////////////////////////////////////////////////////////////////////
// Braincube: ui.js
// 
// Setup general-use UI elements on the admin
//////////////////////////////////////////////////////////////////////////////

braincube.admin.ui = {
	
	// Setup the UI elements across the admin
	init: function(){
		this.setup_flash();					// Setup the flash clear handler
		this.pagination.init();			// Setup any pagination
		this.setup_tabbed_forms();	// Setup any tabbed forms
		this.setup_date_pickers();	// Setup date and time picker inputs
	},
	
	// Handle effects for the flash message
	setup_flash: function(){
		
		// Do the highlight effect
		$(".flash_wrapper").children().effect('flash_highlight', 1000);

		// Click to close
		$(".flash_wrapper").click(
			function(e){
				$(this).children().css("background-image", "none");
				$(this).children().hide("blind", 500);
				$(this).hide("blind", 500);
				return false;
			}
		);
		
	},
	
	// Setup the tab JS on any tabbed fieldsets
	setup_tabbed_forms: function(){
		
		// Return unless there are tabbed fieldsets to process
		if( $(".tabbed_fieldsets:not(.disable_tabs)").length===0 ){ return; }
		
		// Enable the tabs
		$(".tabbed_fieldsets:not(.disable_tabs)").addClass("tabs_enabled");
		$(".tabbed_fieldsets:not(.disable_tabs) ul.tabs").tabs(".tabbed_fieldsets > fieldset");
		
		// If any tabs have errors, update the corresponding link to include
		// an error notification on it.
		$(".tabbed_fieldsets:not(.disable_tabs) > fieldset").each(function(){
			if( $(this).find(".field_with_errors").length>0 ){
				$(this).parent().find("a[href=#"+$(this).attr("id")+"]").addClass("has_error");
			}
		});
		
	},
	
	setup_date_pickers: function(){
		
		// Date-only fields
		$("input.date").datepicker({
			dateFormat: "yy-mm-dd",
			showButtonPanel: true
		});
		
		// Datetime fields
		$("input.datetime").datepicker({
			showTime: true,
			dateFormat: "yy-mm-dd",
			showAnim:"",
			time24h: true,
			showButtonPanel: true
		});
		
	}
	
};