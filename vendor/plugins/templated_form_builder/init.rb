require 'templated_form_builder'

module ActionView::Helpers::FormHelper
  %w(form_for remote_form_for fields_for).each do |helper|
    src = <<-end_src
      def tpl_#{helper}(object_name, *args, &proc)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options.merge! :builder => TemplatedFormBuilder
        #{helper}(object_name, *(args << options), &proc)
      end
    end_src
    
    class_eval src, __FILE__, __LINE__
  end
end
