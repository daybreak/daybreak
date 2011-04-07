module Admin::SeriesHelper
	include MarkupHelpers::Toggles
	include MarkupHelpers::TabControl
	include MarkupHelpers::Radiant

	def message_links(series)
		series.messages.collect{|message| link_to(message.title, "/admin/message/edit/#{message.id}") }
	end
end

