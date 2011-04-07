module ShareLayouts::Helper
  class TransactionBreak < StandardError; end

  def radiant_layout(name = @radiant_layout)
    returning String.new do |output|
      page = ShareLayouts::RailsPage.new(:class_name => "ShareLayouts::RailsPage")
      assign_attributes!(page, name)
      page.build_parts_from_hash!(extract_captures)
      output << page.render
    end
  end

  def assign_attributes!(page, name = @radiant_layout)
    page.layout = Layout.find_by_name(name)
    page.title = @title || @content_for_title || ''
    page.breadcrumbs = @breadcrumbs || @content_for_breadcrumbs || ''
    page.request_uri = request.request_uri
    page.request = request
    page.response = response
  end

  def extract_captures
    variables = instance_variables.grep(/@content_for_/)
    variables.inject({}) do |h, var|
      var =~ /^@content_for_(.*)$/
      key = $1.intern
      key = :body if key == :layout
      unless key == :title || key == :breadcrumbs
        h[key] = instance_variable_get(var)
      end
      h
    end
  end

#TODO: support snippets from Rails side
#  def snippet(name=nil)
#    snippet = Snippet.find_by_name(name) if name
#    if snippet
#      page.render_snippet(snippet)
#    else
#      ""
#    end
#  end
#  module_function :snippet
end

