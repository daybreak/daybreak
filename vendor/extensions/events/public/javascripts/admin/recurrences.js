function init_tabs() {
  var tabControl = new TabControl('tab-control');
  tabControl.addTab('details-tab', 'details', 'details-page');
  tabControl.addTab('pre-registration-tab', 'pre-registration'  , 'pre-registration-page');
  tabControl.addTab('post-registration-tab', 'post-registration', 'post-registration-page');
  tabControl.select(tabControl.firstTab());
};

Event.observe(window, 'load', init_tabs, false);
