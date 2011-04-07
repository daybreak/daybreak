class PageSizesExtension < Radiant::Extension
  version "0.5"
  description "Tracks the overall weight of the content for a page"
  url "http://github.com/mlanza/radiant-page-sizes-extension"


  def activate
    admin.page.index.add :sitemap_head, 'size_th'
    admin.page.index.add :node, 'size_td'

  	Radiant::Config['page_sizes.ignored_parts'] ||= "keyword, backup, bkup, owner, todos, css, js"

    Page.class_eval do
      def kilobytes
        bytes = Float.induced_from(self.parts.reject{|part|ignored_parts.include?(part.name)}.map{|part| (part.content || '').length}.inject(0){|b,i| b+i})
        (bytes/1000).round(2)
      end

      def parts_with_content
        self.parts.reject{|part|ignored_parts.include?(part.name)}.select{|part| (part.content || '').length > 0}
      end
      
      def ignored_parts
        Radiant::Config['page_sizes.ignored_parts'].split(",").map{|p|p.strip}.uniq  
      end
    end
  end

  def deactivate
  end

end

