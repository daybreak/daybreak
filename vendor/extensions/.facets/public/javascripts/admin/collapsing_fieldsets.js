$j(document).ready(function() {
	var legends = $j("fieldset.data > legend, fieldset.expanded > legend, fieldset.collapsed > legend");
 	legends.addClass('open');

  legends.toggle(function() {
		return $j(this).each(function(){
			var legend = $j(this);
			var fieldset = legend.parent('fieldset');
			legend.siblings().hide();
			fieldset.removeClass('open').addClass('closed');
		});
  }, function() {
		return $j(this).each(function(){
			var legend = $j(this);
			var fieldset = legend.parent('fieldset');
			legend.siblings().show();
			fieldset.removeClass('closed').addClass('open');
		});
  });

  $j("fieldset.collapsed > legend").click();

  $j("fieldset.data > legend").each(function(){
  	legends = $j(this);
		legends.each(function(){
			var legend = $j(this);
			var fieldset = legend.parent('fieldset');
			var has_data = false;
			var inputs = fieldset.find(":input");
			var errors = fieldset.find("div.error");
			inputs.each(function(){
				var input = $j(this);
				var value = input.val();
				has_data = has_data || value.length > 0;
			});
			if (!has_data && errors.length == 0) {
				legend.click();
			}
		});
  });
});

