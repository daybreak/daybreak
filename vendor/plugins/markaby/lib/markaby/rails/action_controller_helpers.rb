module Markaby
  module Rails
    module ActionControllerHelpers
      # Returns a string of HTML built from the attached +block+.  Any +options+ are
      # passed into the render method.
      #
      # Use this method in your controllers to output Markaby directly from inside.
      def render_markaby(options = {}, &block)
        render options.merge({ :text => Builder.new(options[:locals], self, &block).to_s })
      end
    end
  end
end