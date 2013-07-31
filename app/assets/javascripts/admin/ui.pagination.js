//////////////////////////////////////////////////////////////////////////////
// Braincube: ui.pagination.js
// 
// Setup pagination tools on the admin
//////////////////////////////////////////////////////////////////////////////

braincube.admin.ui.pagination = {
	
	// Store some bits of information
	timer: null,
	currentPage: 1,
	loading: false,
	enabled: true,
	
	init: function(){
		
		// Only activate if we need it
		if( $("#pagination_wrapper").length===0 ){ return; }
			
		// Scroll event - check how far down we are, maybe request another page
		// if we're near the bottom of the document.
		$(document).scroll( this.checkScroll );
		
		// Disable autocomplete and submission
		$("#search_field").attr("autocomplete", "off");
		$("#search_field").closest("form").bind("submit", function(){ return false; });
		
		// Watch the search field for updates and submit search
		$("#search_field").keyup(function(){
			
			// If we're running a search, then pagination should be re-enabled (if
			// it was previously disabled because we hit the end)
			this.enabled = true;
			clearTimeout(this.timer);
			$("#search_spinner").show();
			
			// Submit the search after a short delay (i.e. only submit a search a
			// short while after the user has stopped typing)
			this.timer = setTimeout(braincube.admin.ui.pagination.submit_search, braincube.admin.jsconfig.paginated_search_timeout);
		
		});
		
	},

	// The handler for actually submitting a search from the search box
	submit_search: function(){
		
		// Reload the current page with the content of the search field in the 
		// q parameter
		$.get( location.href, { q:$("#search_field").val() }, function(html){
			
			// If there is a table in the list, then we have to update the rows in
			// it by updating the tbody element. If not, we update the whole wrapper
			// area instead.
			if ($("#pagination_wrapper tbody").length===1){
				$("#pagination_wrapper tbody").html( html );
			} else {
				$("#pagination_wrapper").html( html );
			}
			
			// Hide the spinner
			$("#search_spinner").hide();
			
		});	
		
	},

	// Check to see if we're near the bottom of the page.
	checkScroll:function() {
		
		_this = braincube.admin.ui.pagination;
		
	  if ( _this.enabled && _this.nearBottomOfPage() && !_this.loading) {
		
			// We're near the bottom of the page, so get another page of results.
			_this.loading = true;
			$("#pagination_loading").show();
			_this.currentPage++;
	
			// Do a request for the current URL. Keep the current search terms in there
			// and send the new page number.
			$.get( location.href, { page:_this.currentPage, q:$("#search_field").val() }, function(html){
				
				// Disable pagination if there were no results - we're at the end of 
				// the list
				if( html.length===0 ){
					_this.enabled = false;
				} else {
					if ( $("#pagination_wrapper tbody").length===1 ){
						$("#pagination_wrapper tbody").append( html );
					} else {
						$("#pagination_wrapper").append( html );
					}
				}
				
				// And we're done
				_this.loading = false;
				$("#pagination_loading").hide();
				
			});
	  }
	},

	// Determine if we're near enough to the bottom of the document to load
	// another page of results
	nearBottomOfPage: function() {
	  return (this.scrollDistanceFromBottom() < 700);
	},

	// How close to the bottom are we?
	scrollDistanceFromBottom: function(argument) {
	  return this.pageHeight() - (window.pageYOffset + self.innerHeight);
	},

	pageHeight: function() {
	  return Math.max(document.body.scrollHeight, document.body.offsetHeight);
	}
};