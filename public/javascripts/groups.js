function hide_columns(css_selector)
{
  $$(css_selector).each(Element.hide);
}

function show_columns(css_selector)
{
  $$(css_selector).each(Element.show);
}
