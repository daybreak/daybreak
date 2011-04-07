document.observe('dom:loaded', function() {
  activateTab($('tab-control'));
});

function activateTab(element) {
  tabControl = new TabControl(element);

  $$('#pages div.page').each(function(page, index) {
    tab = page.id.split('-')[0];
    tabControl.addTab('tab-' + tab, tab.gsub('_', ' ').capitalize(), page.id);
  });

  tabControl.select(tabControl.firstTab());
  tabControl.autoSelect();
}

