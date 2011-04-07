module Admin::MessagesHelper
	include MarkupHelpers::Toggles
	include MarkupHelpers::TabControl
	include MarkupHelpers::Radiant

  def link_to_view_on_site(message)
    link_to('View On Site', :controller => '/messages', :action => 'show', :id => message.id)
  end

  def markaby(&block)
    Markaby::Builder.new({}, self, &block).to_s
  end
end

