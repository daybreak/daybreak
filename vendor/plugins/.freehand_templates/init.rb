require 'action_view'
require 'freehand_templates'
ActionView::Template.register_template_handler :free, Freehand::TemplateHandler
#ActionView::Template.register_template_handler :free, Freehand::Rails::TemplateHandler

