function init_calendar_filter()
{
  var f = $$("input.filter");
  for(var i=0; i<f.length; i++){
    apply_filter(f[i], true);
  }
  apply_filter($$("input.padded_filter")[0], true);
  
	Event.observe($('starred'), 'change', function() {
		var checked = $('starred').checked;
		if (checked)
			$$('tr.unstarred').each(Element.fade);
		else
			$$('tr.unstarred').each(Element.appear);
	});  
}

function apply_filter(checkbox, immediately)
{
    items = $$('.' + checkbox.value)
    if (immediately)
    {
      if (checkbox.checked)
        items.each(Element.show);
      else
        items.each(Element.hide);
    }
    else
    {
      if (checkbox.checked)
        items.each(Element.appear);
      else
        items.each(Element.fade);
    }
}

Event.observe(window, 'load', init_calendar_filter, false);


