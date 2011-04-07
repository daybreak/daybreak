(function($){

	$.fn.zoomIn = function(options){
		options = $.extend({queue: true, easing: 'easeInQuad', duration: 500}, options);
		return this.each(function(){
			var el = $(this).show(); //may be hidden
			var h = el.height(), w = el.width();
			var t = parseInt(el.css('marginTop')), r = parseInt(el.css('marginRight')), b = parseInt(el.css('marginBottom')), l = parseInt(el.css('marginLeft'));
			//console.log('h', h, 'w', w, 'margin', t, r, b, l);
			el.css({width: 0, height: 0, marginTop: t+(h/2), marginRight: r+(w/2), marginBottom: b+(h/2), marginLeft: l+(w/2)});
			el.animate({height: h, width:w, marginTop: t, marginLeft: l, marginBottom: b, marginRight: r}, options.duration, options.easing, options.callback);
		});
	};

})(jQuery);

