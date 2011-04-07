module ParameterizedSnippets
	module Snippet
  	def parameterize(tag)
      self.filter.params = tag.attr.merge('tag' => tag, 'page' => tag.globals.page)
      self
  	end
	end

  #IMPORTANT: Other extensions may override the snippets tag.  Make sure to add the parameterize line to those extensions.
  module Tags
    include Radiant::Taggable
    tag 'snippet' do |tag|
      raise TagError.new("`snippet' tag must contain `name' attribute") unless name = tag.attr['name']
      raise TagError.new('snippet not found') unless snippet = ::Snippet.find_by_name(name.strip)
      snippet.parameterize(tag)
      tag.locals.yield = tag.expand if tag.double?
      tag.globals.page.render_snippet(snippet)
    end
  end

  module TextFilter
    def params=(parameters)
      @params = parameters
      @params.each {|k, v| instance_variable_set("@#{k}", v)}
    end

    def params
      @params || {}
    end
  end
end

