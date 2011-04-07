class ParameterizedSnippetsExtension < Radiant::Extension
  version       "1.0"
  description   "Parameterizes snippet tags for use with a dynamic (e.g. markaby/erb) filter."
  url           "http://github.com/mlanza/radiant-parameterized_snippets-extension"

  def activate
    Page.send :include, ParameterizedSnippets::Tags
    Snippet.send :include, ParameterizedSnippets::Snippet
    TextFilter.send :include, ParameterizedSnippets::TextFilter
  end
end

