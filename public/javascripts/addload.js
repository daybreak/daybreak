// Author: Simon Willison

public function addLoadEvent(func) {
  var oldonload = window.onload;
  if (typeof window.onload != 'function') {
    window.onload = func;
  } else {
    window.onload = function() {
      if (oldonload) {
        oldonload();
      }
      func();
    }
  }
}

//addLoadEvent(functionName);
//   OR
//addLoadEvent(function() {
//  /* more code to run on page load */ 
//});
