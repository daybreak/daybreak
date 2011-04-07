$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'markaby'
require 'markaby/rails/template_handler'
require 'markaby/rails/action_controller_helpers'

ActionView::Template.register_template_handler 'mab', Markaby::Rails::TemplateHandler
ActionController::Base.send :include, Markaby::Rails::ActionControllerHelpers