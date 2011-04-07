document.observe('dom:loaded', function() {
  Event.observe('event_register', 'click', setRegistrationTabsVisibility);
  Event.observe('repeat_mode', 'change', setVisibility);
  applyColor();
  setRegistrationTabsVisibility();
  setVisibility();
});


function applyColor(){
  var color_sample = $("color_sample");
  var color = $("event_invitation_color").value;
  color_sample.style.backgroundColor = "";
  color_sample.style.backgroundColor = color;
}

function showRegistrationTabs(visible){
  var display = visible ? '' : 'none';
  $$('#tabs > a.tab > span').each(function(tabname, index) {
    if (tabname.innerHTML == 'Registrations' || tabname.innerHTML == 'Registrants') {
      tab = tabname.up();
      if (visible)
        tab.show();
      else
        tab.hide();
    }
  });
//  desc[4].style.display = display;
//  try {
//    $('registrations-tab').style.display = display;
//  } catch(err) {}
}

function setRegistrationTabsVisibility(){
  showRegistrationTabs(hasRegistrants() || allowRegistrations());
}

function hasRegistrants() {
  return $('num_registrants').textContent != '0';
}

function allowRegistrations() {
  return $('event_register').checked;
}

function setVisibility()
{
  switch($('repeat_mode').value)
  {
    case 'Monthly':
      $('repeat_ordinal').show();
      $('repeat_day').show();
      $('repeat_occurrences').show();
      $('repeat_times').show();
      break;
    case 'Weekly':
      $('repeat_ordinal').hide();
      $('repeat_day').show();
      $('repeat_occurrences').show();
      $('repeat_times').show();
      break;
    case 'Daily':
    case 'Weekdays':
      $('repeat_ordinal').hide();
      $('repeat_day').hide();
      $('repeat_occurrences').show();
      $('repeat_times').show();
      break;
    default:
      $('repeat_ordinal').hide();
      $('repeat_day').hide();
      $('repeat_occurrences').hide();
      $('repeat_times').hide();
      break;
  }
}

