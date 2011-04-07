$: << '/work/plugins/freehand/lib'
$: << '/work/gems/local_variable_set/lib'

require 'freehand'
require 'local_variable_set'
require 'action_view'
require 'action_view/base'
require 'iwish/blank_slate'

class Object
  # The hidden singleton lurks behind everyone
  def metaclass; class << self; self; end; end
  def meta_eval &blk; metaclass.instance_eval &blk; end

  # Adds methods to a metaclass
  def meta_def( name, &blk )
    meta_eval { define_method name, &blk }
  end

  # Defines an instance method within a class
  def class_def( name, &blk )
    class_eval { define_method name, &blk }
  end
end


ActionView::Base.class_eval do
  alias render_without_freehand render
end


module Freehand
  class Renderer < Object
    def initialize(view)
      @view = view
      @view.instance_variables.each do |var|
        self.instance_variable_set(var, @view.instance_variable_get(var))
      end
    end

    def method_missing(method, *args, &block)
      puts "Transferring #{method}"
      @view.send(method, *args, &block)
    end

    def render(*args)
      puts "Rendering"
      @view.text{@view.render(*args)}
    end
  end

  class TemplateHandler < ActionView::TemplateHandler
    def render(template, locals)
      body = [Binding::Cache.cache_locals(locals).restore_locals_script, 'nil', template.source].join("\n")

      #@proxy = Freehand::Renderer.new(@view)


      #def @view.render(*args)
      #  text @render_without_freehand.call(*args)
      #end

      @view.instance_eval{extend Freehand::Taggify}
      @proxy.instance_eval body

      #def @view.render(*args)
      #  @render_without_freehand.call(*args)
      #end


      @view.markup
    end
  end
end

