(function($){

	function pageId(td){
		return td.parents('tr').eq(0).attr('id').split('_')[1];
	}
	
	function homePage(td){
		return td.parents('tr').eq(0).hasClass('level-0');
	}
	
	$(document).ready(function() {
		var $sitemap      = $('#site_map');
		var $instructions = $('#adopt-instructions');
		var $body         = $('body');
		$instructions.hide();
		
		$sitemap.attr('data-adopt-state','idle');
		$('td.adopt').live('click', function(){
			$.each($(this), function(index, value) {
				var $td = $(this);				
				var $role = $td.attr('data-adopt-role');
				
				$sitemap.find('td.adopt').removeAttr('title');
				
				switch($sitemap.attr('data-adopt-state')) {
					case 'idle':                                       //started
						if (!homePage($td)) { //cannot adopt home page
							$td.attr('data-adopt-role','child');
							$sitemap.attr('data-adopt-state', 'in-progress');
							$instructions.show();
						}
						break;
						
					case 'in-progress':
						if ($td.attr('data-adopt-role') == 'child') { //aborted
							$td.removeAttr('data-adopt-role');
							$sitemap.attr('data-adopt-state', 'idle');
							$instructions.hide();
						} else {                                         //finished
							var $parent = $td;
							var $child = $('td.adopt[data-adopt-role=child]');
							if ($child.length > 1) {
								throw('It should not be possible to select more than one child.');
							}

							$body.addClass('adopting');							

							var url = '/admin/pages/' + pageId($parent) + '/adopt/' + pageId($child);

							function adopted(data, status, xhr){
							  location.reload();
							}
							function failed(xhr, status, err){
							  $child.removeAttr('data-adopt-role');
							  $sitemap.attr('data-adopt-state', 'idle');
								$body.removeClass('adopting');
  							alert('Unable to reassign parent of page.');
							}
							
							$instructions.hide();							
              $.ajax({ url: url, success: adopted, error: failed});
						}
						break;
				}
				
			});
		});
	});
})(jQuery);
