//////////////////////////////////////////////////////////////////////////////
// Braincube: login_page.js
// 
// Handles login page
//////////////////////////////////////////////////////////////////////////////

braincube.admin.login_page = {
	
	init: function(){
		
		// Return unless we're on the login page
		if( $("fieldset.login, fieldset.setup").length===0 ){ return; }
		
		// Hide the JS warning
		$(".noscript").hide();
		
		$(".script").show();
	}
	
}