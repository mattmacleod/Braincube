(function() {

	tinymce.PluginManager.requireLangPack('braincube_files');

	tinymce.create('tinymce.plugins.BraincubeFilesPlugin', {

		init : function(ed, url) {

			ed.addCommand('braincubeFiles', function() {
				
				// Get the selection in the current editor and configure the plugin.
				// We assume Braincube admin is always at /admin
				var current_editor_selection = ed.selection;
				var selected_node = current_editor_selection.getNode();
				var target_href = "/admin/asset_folders/attach";
				var is_managed = true;
				var image_regex = /\/assets\/[a-z]+\/[\d+]+\/([\d+]+)/i;
				
				// Store the selected area
				braincube.admin.asset_manager.attachment.stored_selection = current_editor_selection.getBookmark();
				
				// Is the selected item an image? Extract it out and get the filename
				// and other attributes. Also store the link if there is one of those.
				if (selected_node.nodeName == 'IMG') {
										
					// The selected node is an image - try to get the Braincube id
					// of the file by looking at the address
					var file_id = ( selected_node.src.match(image_regex) );
					
					if ( file_id ) {
						
						// This is a managed file, so build the URL of the image management
						// page that we need to access
						target_href = "/admin/asset_folders/attach_variation/" + file_id[1];
						
						// Get the filename out of the attached img tag's source attr
						var filename = selected_node.src.match(/([a-z0-9_\.-]+)$/i);
						
						// Save the details of the embedded image into the JS asset manager object
						if ( filename ) {
							braincube.admin.asset_manager.attachment.active_filename = filename[1];
						}
						
					} else {
						// This doesn't appear to be a managed image.
						is_managed = false;
					}
					
				}
				
				
				if( is_managed ) {
					
					// Editing a managed file - Add Pretty Photo popup details here
					target_href += "?popup=true&iframe=true&width=850&height=" + (document.documentElement.clientHeight - 100)
					
					braincube.admin.asset_manager.attachment.editor_select = true;
					$.prettyPhoto.open( target_href );
					
				} else {
					return
				}
				
			});

			// Add the GB file selector button
			ed.addButton('braincube_files', {
				title : 'braincube_files.desc',
				cmd : 'braincubeFiles',
				image : url + '/img/picture.gif'
			});

			ed.onNodeChange.add(function(ed, cm, n, co) {
				cm.setActive('braincube_files', n.nodeName == 'IMG');
			});
		},

		createControl : function(n, cm) {
			return null;
		},

		getInfo : function() {
			return {
				longname 	: 'Braincube file manager plugin',
				author 		: 'Matthew MacLeod',
				authorurl : 'http://www.braincube.co.uk',
				infourl 	: 'http://www.braincube.co.uk',
				version 	: "1.0"
			};
		}
	});

	tinymce.PluginManager.add('braincube_files', tinymce.plugins.BraincubeFilesPlugin);
	
})();