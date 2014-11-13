//////////////////////////////////////////////////////////////////////////////
// Braincube: asset_manager.js
// 
// Handles the asset manager pages
//////////////////////////////////////////////////////////////////////////////

braincube.admin.asset_manager = {
	
	// Setup the asset manager
	init: function(){
		this.setup_folder_browser();		// Setup the treeview on the browser
		this.setup_pp();								// Setup the image preview box
		this.pagination.init();					// Setup the special-case pagination
		this.cropper.init();						// Setup the cropper
		this.attachment.init();					// Setup image attachment manager
		this.bulk.setup();
	},
	
	// Sets up the treeview for the folder browser using the jQuery treeview
	// plugin.
	setup_folder_browser: function(){
		$(".asset_folder_list").treeview({ animated: "fast", collapsed: true });
		$(".asset_folder_list a.current").parents("li").find(">div").click();
	},
	
	setup_pp: function(){
		$(".pp_pic_holder").remove();
		$(".pp_overlay").remove();
		$(".ppt").remove();
		$("a[rel^='prettyPhoto']").prettyPhoto({theme: "dark_rounded"});
	},

	// Handles custom pagination for the asset browser. Copied from the main 
	// pagination JS. I know I should make it modular, but you know what they
	// say: first time, don't write for the general case. Second time, think 
	// about how you might modularise it in the future. Third time, refactor.
	// I think I fulfilled the second step!
	pagination: {
		
		timer:null,
		currentPage: 1,
		loading: false,
		enabled: true,
		
		init: function(){
			
			if( $("#main_folder_wrapper" ).length===0){ return; }
			
			// Disable auto-complete
			$("#search_field").attr("autocomplete", "off");
			
			$(document).scroll( this.checkScroll );
			
			$("#search_field").keyup( this.setup_search );
			$(".search_form input.radio").change( this.setup_search );
			
		},

		setup_search: function(){
			_this = braincube.admin.asset_manager.pagination;
			_this.enabled = true;
			clearTimeout(_this.timer);
			$("#search_spinner").show();
			_this.timer = setTimeout(_this.submit_search, 400);
		},
		
		submit_search: function(){
			
			$.get( location.href , $(".search_form form").serialize(), function(html){
				$("#main_folder_wrapper").html( html );
				$("#search_spinner").hide();
				braincube.admin.asset_manager.setup_pp();
			});	
			
		},

		checkScroll:function() {

		_this = braincube.admin.asset_manager.pagination;
			
		  if (_this.enabled && _this.nearBottomOfPage() && !_this.loading) {
						
				_this.loading = true;
				
				$("#pagination_loading").show();
		    _this.currentPage++;
		
		    $.get( 
					location.href,
					{ page: _this.currentPage, q: $("#search_field").val() }, 
					function(html){
						// Disable pagination if there were no results
						if(html.length <= 1){
							_this.enabled = false;
						} else {
							$("#main_folder_wrapper").append( html );
							braincube.admin.asset_manager.setup_pp();
						}
					
						_this.loading = false;
						$("#pagination_loading").hide();
					
				});
		  }
		
		},

		nearBottomOfPage: function() {
		  return (_this.scrollDistanceFromBottom() < 500);
		},

		scrollDistanceFromBottom: function(argument) {
		  return _this.pageHeight() - (window.pageYOffset + self.innerHeight);
		},

		pageHeight: function() {
		  return Math.max(document.body.scrollHeight, document.body.offsetHeight);
		}
	},
	
	// Setup the jQuery cropper for asset detail pages
	cropper: {
		
		init: function(){

			// Return if there are no previews to crop
			if( $("fieldset.preview").length===0 ){ return; }

			// When the crop button is clicked, set up the cropper
			$(".tabbed_fieldsets .preview .current_crop a").click(function(){
				
				var pane = $(this).parents(".preview");
				pane.find(".recrop").show();
				pane.find(".current_crop").hide();
				
				// Get the image to crop and the geometry string
				var _this = pane.find(".crop_source");
				
				var geom = pane.find(".geometry").html();
				var aspect_ratio = null;
				
				if( geom[geom.length-1]==="#" ){
					aspect_ratio = geom.split("x")[0] / geom.split("x")[1].replace("#", "");
				} else {
				  aspect_ratio = null;
				}

				var api = $.Jcrop(_this, {

					// Handle completion of the select
					onSelect: function( coords ){
						$(pane).find(".crop_x").val(coords.x);
						$(pane).find(".crop_y").val(coords.y);
						$(pane).find(".crop_w").val(coords.w);
						$(pane).find(".crop_h").val(coords.h);
					},

					aspectRatio: aspect_ratio,
					
					boxWidth: 672

				});
				
				_this.data("jcrop", api);
				
				return false;
				
			});
			
			// Close the cropper
			$(".tabbed_fieldsets .preview .recrop a").click(function(){
				pane = $(this).parents(".preview");
				pane.find(".crop_source").data("jcrop").destroy();
			
				pane.find(".recrop").hide();
				pane.find(".current_crop").show();
				
				$(pane).find(".crop_x").val("");
				$(pane).find(".crop_y").val("");
				$(pane).find(".crop_w").val("");
				$(pane).find(".crop_h").val("");
				
				return false;
			});
			
		}					
	},
	
	attachment: {
		
		// Variables
		stored_selection: null,
		active_filename: null,
		editor_select: false,
		properties: {},
		
		init: function(){

			// Quit if there are no attachment forms here
			if($(".asset_attachment_items,.asset_attachment_window").length===0){ return; }

			var _this = this;
			
			// Setup ordering
			this.setup_ordering();
			
			// Setup clear button
			$(".asset_attachment_tools a.delete").click( this.clear_attachments );
			
			// Setup add button
			$(".asset_attachment_tools a.new").click( this.open_attachment_browser );
			
			// Setup delete buttons
			$(".asset_attachment_items .delete_asset").live("click", function(){ _this.remove_attachment( $(this).parents(".asset") ); return false; });
			
			// Setup use buttons
			$(".asset_use").live("click", this.select_attachment );
			
			// Setup variation selector buttons
			$(".select_variation").live("click", this.select_variation );
			
			// Setup google search
			this.google.init();
			
		},
		
		setup_ordering: function(){
			
			// Create the sortable
			$(".asset_attachment_list").sortable({
				axis: "y", 
				opacity: 0.5,
				placeholder: "placeholder",
				forcePlaceholderSize: true,
				stop: function(event,ui){
					braincube.admin.asset_manager.attachment.set_sort_order();
				}
			});

			// Setup initial sort order fields
			this.set_sort_order();
			
		},
		
		clear_attachments: function(){
			if( $(".asset_attachment_items .asset:visible").length>0 ){
				$(".asset_attachment_items .delete_asset").click();
				$(".asset_attachment_items .empty").show("blind");
			}
			return false;
		},
		
		open_attachment_browser: function(){
			braincube.admin.asset_manager.attachment.editor_select = false;
			$.prettyPhoto.open("/admin/asset_folders/attach?suggestion=" + encodeURI($(".asset_search_suggestion").html() + "&iframe=true&width=850&height=" + (document.documentElement.clientHeight - 100)) );
			return false;			
		},
		
		remove_attachment: function( element ){
			
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
			if( $(".asset_attachment_items input.destroy_field[value=false]").length===0 ){
				$(".asset_attachment_items .empty").show("blind");
			}
			
			return false;
			
		},
		
		set_sort_order: function(){
			var idx = 0;
			$(".asset_attachment_list").find("input.sort_order").each(function(){
				$(this).val( idx++ );
			});
		},
		
		add_attachment: function( thumbnail_path, asset_id ){
				
			$(".asset_attachment_items .empty").hide();
		
			new_id = new Date().getTime();
			var code = $(".attachment_code").attr("data-code").replace(/REPLACE_WITH_THUMBNAIL_PATH/g, thumbnail_path ).replace(/REPLACE_WITH_ASSET_ID/g, asset_id );
			$('.asset_attachment_list').append( code.replace(/\[0\]/g, "["+new_id+"]").replace(/\_0\_/g, "_"+new_id+"_") );
			this.set_sort_order();
				
		},
		
		select_attachment: function(){
			
			// Decide what to do by checking if we're in the editor or not
			if( parent.braincube.admin.asset_manager.attachment.editor_select ){
				// We need to either display the variation selector page if this is
				// an image, or we need to select the file, wrap it in a link and
				// insert it into the editor
				if( $(this).hasClass("linked") ){
					// Get url from download button
					parent.braincube.admin.asset_manager.attachment.insert_editor_document( $(this).attr("href"), $(this).siblings(".asset_download").attr("href") );
					parent.$.prettyPhoto.close();
				} else {
					window.location.href = "/admin/asset_folders/attach_variation/" + $(this).attr("id");
				}
				return false;
			} else {
				// We are not in the editor, so we use the standard attachment method
				parent.braincube.admin.asset_manager.attachment.add_attachment( $(this).attr("href"), $(this).attr("id") );
				parent.$.prettyPhoto.close();
				return false;
			}
		},

		select_variation: function( ){
			parent.braincube.admin.asset_manager.attachment.insert_editor_image( $(this).attr("href") );
			parent.$.prettyPhoto.close();
			return false;
		},
		
		insert_editor_image: function( thumbnail_path ){
		
			var ed = tinyMCE.activeEditor, args = {}, el;
			ed.selection.moveToBookmark( this.stored_selection );

			args = {
				src: thumbnail_path
			};

			el = ed.selection.getNode();

			if (el && el.nodeName === 'IMG') {
				ed.dom.setAttribs(el, args);
			} else {
				ed.execCommand('mceInsertContent', false, '<img id="__mce_tmp" src="#" />');
				ed.dom.setAttribs('__mce_tmp', args);
				ed.dom.setAttrib('__mce_tmp', 'id', '');
			}
				
		},
		
		insert_editor_document: function( thumbnail_path, file_path ){
		
			var ed = tinyMCE.activeEditor, args = {}, el;
			ed.selection.moveToBookmark( this.stored_selection );

			img_args = {
				src: thumbnail_path
			};
			
			link_args = {
				href: file_path
			};
			
			el = ed.selection.getNode();

			if (el && el.nodeName === 'A') {
				ed.dom.setAttribs(el, link_args);
			} else {
				ed.execCommand('mceInsertContent', false, '<a id="__mce_tmp_link" class=' + ("popup " + file_path.split(".")[1]) + '><img id="__mce_tmp" src="#" /></a>');
				ed.dom.setAttribs('__mce_tmp_link', link_args);
				ed.dom.setAttrib('__mce_tmp_link', 'id', '');
				
				ed.dom.setAttribs('__mce_tmp', img_args);
				ed.dom.setAttrib('__mce_tmp', 'id', '');
			}

		},
		
		google: {
			
			init: function(){
				
				// Return unless there's a search area
				if($(".google_image_search").length===0){ return; }

				// Load from the Google API
				google.load('search', '1', {"callback" : braincube.admin.asset_manager.attachment.google.load_search});
				
				// Hook into the download links
				$(".google_image_search .asset_download").live("click", function(){
					$("#google_url_upload_url").val( $(this).attr("href") );
					$("#new_google_url_upload").submit();
					return false;
				});
				
				// Auto search on tab click if field populated
				$("a[href=#google]").click( function(){
					if($("#google_search_query input").val().length>0){
						$("#google_search_query a").click();
					}
				});
				
			},
			
			load_search: function(){
								
				// Setup search
				var search_object = new google.search.ImageSearch();

				search_object.setSearchCompleteCallback(this, braincube.admin.asset_manager.attachment.google.display_results, [search_object]);
				search_object.setResultSetSize(google.search.Search.LARGE_RESULTSET);
				
				// Include the required Google branding
				google.search.Search.getBranding('google_branding');
				
				// Hook into the search button
				$("#google_search_query a").click(function(){
					search_object.execute($(this).siblings("input").val());
					return false;
				});
				
			},

			
			display_results: function(a){
				
				results = a.results;
				
				$(".google_image_search").html("");
				
				// Loop through our results, printing them to the page.				
				for ( i = 0; i < results.length; i++) {
										
					var result = results[i];
					str = "<div class='result'><div class='thumb'><img src='" + result.tbUrl + "'/></div><div class='label'><strong>" + result.titleNoFormatting + "</strong><span class='source'>" + result.visibleUrl + "</span><em><a href='" + result.url + "' class='asset_show' rel='prettyPhoto'>Show</a><a href='" + result.url + "' class='asset_download'>Download</a></em><div class='clear'></div></div>";
					$(".google_image_search").append(str);

				}
				
				// Setup PP links
				braincube.admin.asset_manager.setup_pp();
				
			}
			

		}
				
	},

	bulk: {

		setup: function(){

			if( !$("#asset_dnd").length ){ return };

			$("body").dropzone({

				previewsContainer: "#asset_dnd",
				url:               $("#asset_dnd").attr("action"),
				paramName:         "asset[asset]",
				previewTemplate:   "<div class=\"dz-preview dz-file-preview\">\n  <div class=\"dz-details\">\n    <div class=\"dz-filename\"><span data-dz-name></span></div>\n    <div class=\"dz-size\" data-dz-size></div>\n    <img data-dz-thumbnail />\n  </div>\n  <div class=\"dz-progress\"><span class=\"dz-upload\" data-dz-uploadprogress></span></div>\n<div class=\"dz-error-message\"><span data-dz-errormessage></span></div>\n</div>",
				clickable:         false,

				fallback: function(){
					$(this).remove();
				},

				success: function(file, responseText, e){
					$(file.previewTemplate).remove();
					var $new_element = $(responseText);
					$("#main_folder_wrapper").prepend($new_element);
					$("#main_folder_wrapper div.note").remove();
				},

				error: function(file, message) {
					$(file.previewTemplate).addClass("error").append(
						$("<a class='close'>Close</a>").bind("click", function(){
							$(file.previewTemplate).remove();
						})
					).find(".error-message span").text(message);
				},

				sending: function(file,xhr){
			      var token = $('meta[name="csrf-token"]').attr('content');
			      if (token) xhr.setRequestHeader('X-CSRF-Token', token);
				}

			});


		}

	}
	
};