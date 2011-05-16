braincube.admin.widgets = {
	
	init: function(){
		this.setup_widget_manager_tabs();
	},
	
	setup_widget_manager_tabs: function(){
		
		// Return unless needed
		if( $(".widget_forms").length===0 ){ return; }
		
		// Setup handlers on the type drop-down
		$("#widget_widget_type").change(this.update_widget_manager_tabs).change();
		
	},
	
	update_widget_manager_tabs: function(){
		
		// Hide all tabs
		$(".type").hide();
		
		// Show selected tab
		$("#widget_type_" + $("#widget_widget_type").val() + "_tab").show();
		
		
	}
	
}