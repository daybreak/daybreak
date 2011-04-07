class BookmarkingExtension < Radiant::Extension
  version "1.0"
  description "Tracks bookmarks" #requires is_taggable gem
  url ""

  define_routes do |map|
    map.admin_bookmark 'admin/bookmarks/:action/:id', :controller => 'admin/bookmarks'
  end

  def activate
    index = (admin.page || admin.pages).index
	  index.add :sitemap_head, "admin/pages/bookmarking_th"
    index.add :node,         "admin/pages/bookmarking_td"
    index.add :top,          "admin/pages/bookmarking_head"

    User.class_eval do
	    is_taggable :bookmarked_pages

			def bookmark?(item)
	    	taggable = item.is_a?(Page) ? 'page' : item.class.to_s.underscore
				tags.detect{|t| t.kind == "bookmarked_#{taggable}" && t.name == item.id.to_s}
			end

	    def bookmark(item)
	    	taggable = item.is_a?(Page) ? 'page' : item.class.to_s.underscore
	    	tags.detect{|t| t.kind == "bookmarked_#{taggable}" && t.name == item.id.to_s} || tags.create(:kind => "bookmarked_#{taggable}", :name => item.id.to_s)
	    end

	    def unbookmark(item)
		    taggable = item.is_a?(Page) ? 'page' : item.class.to_s.underscore
				tags.detect{|t| t.kind == "bookmarked_#{taggable}" && t.name == item.id.to_s}.try(:destroy) && tags.reload
	    end
    end
  end
end

