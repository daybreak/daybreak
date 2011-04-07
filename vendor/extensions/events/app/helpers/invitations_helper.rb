module InvitationsHelper
	def to_calendar_page(date)
<<HERE
	<div class='calendar_page'>
		<div class='month'>#{date.strftime('%B')}</div>
		<div class='day'>#{date.strftime('%e')}</div>
	</div>
HERE
	end
end

