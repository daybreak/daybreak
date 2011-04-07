class NotFoundWithRewritesPage < FileNotFoundPage
  def cache?
    false
  end

  def mappings
    # [['/old','/new'],...]
    @mappings ||= begin
      rewrite_part = Radiant::Config['nostalgia.rewrites_part_name']
      lines = render_part(rewrite_part).split(%{\r\n})
      lines.inject([]){|res,line| res << line.split(/ +\=> +/, 2);res}
    end

    #TODO: extra into a separate piece using "super" and a mixin
    keywords = PagePart.all(:conditions => {:name => 'keyword'}, :include => :page)
    @keyword_mappings = keywords.select{|part| part.page }.map do |part|
      original = "/#{part.content.chomp}"
      rewrite = part.page.url
      [original, rewrite]
    end

    @mappings + @keyword_mappings
  end

  def process(request, response)
    super
    request_uri = request.request_uri
    if location = find_and_apply_rewrite(request_uri)
      @response.headers["Location"] = location
      @response.body = <<-HTML
<html>
  <body>
    You are being <a href=\"#{CGI.escapeHTML(location)}\">redirected</a>.
  </body>
</html>
      HTML
      @response.status = 301
      @not_found_request.decrement_count_created!
    end
  end

  protected
  def find_and_apply_rewrite(uri)
    captures = nil
    match = mappings.detect do |(from,to)|
      re = %r{^#{from}$}
      captures = uri.scan(re).flatten
      captures.any?
    end
    return nil unless match
    to = match.last
    build_path_from_captures(to, captures)
  end

  def build_path_from_captures(path, captures)
    captures.each_with_index do |cap, ix|
      path.gsub!("$#{ix+1}", cap)
    end
    path
  end
end

