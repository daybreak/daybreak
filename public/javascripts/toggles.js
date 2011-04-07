document.observe('dom:loaded', function() {
  var toggle = function(e) {
    var ele = e.element();
    var ta  = e.findElement('.togglearea');
    var cn  = ta.classNames();

    if (cn.include('off')) {
      cn.remove('off');
      cn.add('on');
    } else if (cn.include('on')) {
      cn.remove('on');
      cn.add('off');
    }
  }
  var togglers = $$('.togglearea .toggler > a');
  togglers.each(function(toggler) {
    Event.observe(toggler, 'click', toggle);
  });
});

