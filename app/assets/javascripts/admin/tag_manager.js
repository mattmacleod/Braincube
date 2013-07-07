//////////////////////////////////////////////////////////////////////////////
// Braincube: tag_manager.js
// 
// Admin tag manager
//////////////////////////////////////////////////////////////////////////////

braincube.admin.tag_manager = {
	
	init: function(){
		this.setup_delete_buttons();
	},

	setup_delete_buttons: function(){
		$("span.tag a.delete").live("click", function(){
			confirm("Are you sure you want to delete this tag?");
		});
	}

}