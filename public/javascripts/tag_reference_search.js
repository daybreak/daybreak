function hasWordInElement(word, element) {
  if (element.nodeType == Node.TEXT_NODE) {
    return element.nodeValue.include(word) != null;
  } else {
    return $A(element.childNodes).any(function(child) { 
      return hasWordInElement(word, child); 
    });
  }
}

var searchingOn = ""

function observeTagSearch(element, value) {
  if (value.length < 3 && searchingOn != "") {
    searchingOn = "";
    $$("div.tag-description").invoke('show');
  } else if (value.length >= 3 && searchingOn != value) {
    searchingOn = value
    $$("div.tag-description").each(function(div) {
      div[hasWordInElement(value, div) ? 'show' : 'hide']();
    });
  }
}
