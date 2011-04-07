document.observe('dom:loaded', function() {
  when('site-map', function(table) { new SiteMap(table) });

  when('page_title', function(title) {
    var slug = $('page_slug'),
        breadcrumb = $('page_breadcrumb'),
        oldTitle = title.value;
    
    if (!slug || !breadcrumb) return;
    
    new Form.Element.Observer(title, 0.15, function() {
      if (oldTitle.toSlug() == slug.value) slug.value = title.value.toSlug();
      if (oldTitle == breadcrumb.value) breadcrumb.value = title.value;
      oldTitle = title.value;
    });
  });

  when($$('#pages div.part > input[type=hidden]:first-child'), function(parts) {
    tabControl = new TabControl('tab-control');
    
    parts.each(function(part, index) {
      var page = part.up('.page');
      tabControl.addTab('tab-' + (index + 1), part.value, page.id);
    });

    tabControl.autoSelect();
  });
});

// When object is available, do function fn.
function when(obj, fn) {
  if (Object.isString(obj)) obj = /^[\w-]+$/.test(obj) ? $(obj) : $(document.body).down(obj);
  if (Object.isArray(obj) && !obj.length) return;
  if (obj) fn(obj);
}

function part_added() {
  var partNameField = $('part-name-field');
  var partIndexField = $('part-index-field');
  var index = parseInt(partIndexField.value) + 1;
  var tab = 'tab-' + index;
  var caption = partNameField.value;
  var page = 'page-' + index;
  tabControl.addTab(tab, caption, page);
  Element.hide('add-part-popup');
  Element.hide('busy');
  partNameField.value = '';
  partIndexField.value = (index + 1).toString();
  $('add-part-button').disabled = false;
  Field.focus(partNameField);
  tabControl.select(tab);
}
function part_loading() {
  $('add-part-button').disabled = true;
  $('busy').appear();
}
function valid_part_name() {
  var partNameField = $('part-name-field');
  var name = partNameField.value.downcase().strip();
  var result = true;
  if (name == '') {
    alert('Part name cannot be empty.');
    return false;
  }
  tabControl.tabs.each(function(pair){
    if (tabControl.tabs.get(pair.key).caption == name) {
      result = false;
      alert('Part name must be unique.');
      throw $break;
    }
  })
  return result;
}
function center(element) {
  var header = $('header')
  element = $(element);
  element.style.position = 'absolute';
  var dim = Element.getDimensions(element);
  var top = document.documentElement.scrollTop ? document.documentElement.scrollTop : document.body.scrollTop;
  element.style.top = (top + 200) + 'px';
  element.style.left = ((header.offsetWidth - dim.width) / 2) + 'px';
}
function toggle_add_part_popup() {
  var popup = $('add-part-popup');
  var partNameField = $('part-name-field');
  center(popup);
  Element.toggle(popup);
  Field.focus(partNameField);
}
