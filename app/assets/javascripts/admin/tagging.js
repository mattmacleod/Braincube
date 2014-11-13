//////////////////////////////////////////////////////////////////////////////
// Braincube: tagging.js
// 
// Handles tag entry fields
//////////////////////////////////////////////////////////////////////////////

braincube.admin.tagging = {

	init: function(){
		
		// Return unless there is a tag entry field on this page
		if( $(".tag_select").length===0 ){ return; }
		
		this.setup_autocomplete();	// Set up the autocomplete and tokenization
		this.setup_links();					// Set up the most popular links
		
	},


	// Sets up the JQUI autocomplete widget for the tag select field.
	setup_autocomplete: function(){
		
		$(".tag_select").autocomplete({
			
			// Gets the source of the tags through an AJAX request for JSON from
			// the tag listing page.
			source: function( request, response ) {
				
				$.ajax({
					
					url: "/admin/tags",
					dataType: "json",
					data: { q: braincube.admin.tagging.extract_last(request.term) },
					
					// Process the returned JSON to get a list of the tags - the name
					// and value is to be the same.
					success: function( data ) {
						response( $.map( data, function( item ) {
							return { label: item.name, value: item.name };
						}));
					}
					
				});
				
			},
			
			// Don't do anything on intial focus
			focus: function() {
				return false;
			},
			
			// When an item is selected from the list, add it to the end of the
			// field contents.
			select: function( event, ui ) {
				
				// Get the current terms in the search box
				var terms = braincube.admin.tagging.split_list( this.value );
				
				// Add the new term to the end
				terms.pop();
				terms.pop();
				terms.push( ui.item.value );
				terms.push( "" );
				
				// Update the field with the new string
				this.value = terms.join( ", " );
				$(this).focus().val(this.value);
				
				return false;
				
			}
		});
		
		// Handle commas on the end of the inputs - add a comma when focusing, 
		// remove when blurring.
		$(".tag_select").blur(
			function(){
				$(this).val( $(this).val().replace( /,\s$/g, "" )) ;
			}
		).focus( 
			function(){
				if( !$(this).val().match(/,\s$/g) && !( $(this).val() === "" ) ){
					$(this).val( $(this).val() + ", ");
				}
			}
		);
	},
	
	// Set up the popular tag links, so they add a tag to the list when clicked
	setup_links: function(){
		
		// Find the correct list of tag links
		$(".tag_select").siblings(".tag_attachment_list").find("a.tag").click(
			function(){
				
				// Add this tag to the list
				$(this).parent().siblings(".tag_select").val( 
					$(this).parent().siblings(".tag_select").val() ?  $(this).parent().siblings(".tag_select").val() + ", " + $(this).attr("title") : $(this).attr("title")
				);
				
				// Hide the tag once it's been clicked
				$(this).hide("slide");
				return false;

		});
	},
	
	// Split a list of tags on commas
	split_list: function( list ){
		return list.split( /,\s*/ );
	},
	
	// Get the last term from the text field
	extract_last: function( term ){
		return this.split_list( term ).pop();
	}
	
};