module Markaby
  module Rails
    class TemplateHandler < ActionView::TemplateHandler
      include ActionView::TemplateHandlers::Compilable

      def compile(template)
        <<-CODE
          @output_buffer = '' if @output_buffer.blank?;

          output = Markaby::Builder.new(assigns.merge(local_assigns), self);
          output.copy_instance_variables_from(self, [:@helpers, :@assigns]);
          output.instance_eval(#{template.source.dump});
          output.to_s;
        CODE
      end
    end
  end
end