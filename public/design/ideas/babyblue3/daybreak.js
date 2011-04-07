
sunpos = 140;
sunrise = function(){
	if (typeof executer == 'undefined') {
		executer = new PeriodicalExecuter(function(){
			$('risingsun').style.backgroundPosition = "80% " + sunpos + "px";
			sunpos -= 1;
			if (sunpos < 40)
			{
				executer.stop();
				executer = undefined;
			}
		}, .02);
	}
};



