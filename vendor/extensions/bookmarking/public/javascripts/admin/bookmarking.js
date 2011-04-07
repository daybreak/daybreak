(function($){

  $(document).ready(function(){
    var $body = $('body');
    $('img.bookmark, img.unbookmark').live('click', function() {
      $body.addClass('bookmarking');    
      var img = $(this);
      var action = img.hasClass("bookmark") ? 'bookmark' : 'unbookmark';
      var page_id = img.attr("class").replace('unbookmark','').replace('bookmark', '').replace('page-','').trim();
      var toggled = ('un' + action).replace('unun','');
      var target = '/admin/bookmarks/page/' + page_id + '?_method=' + (action == 'bookmark' ? 'put' : 'delete');
      $.ajax({ url: target, success: function(){
        img.removeClass('bookmark').removeClass('unbookmark').addClass(toggled);
      }, complete: function(){
        $body.removeClass('bookmarking')
      }});
    });
  });

})(jQuery);

