module Admin
  module PageOriginController
 
    def self.included(base)
      base.class_eval do
        
        before_filter :include_page_origin_assets
        helper_method :parent_archive_page?, :full_base_url
        
        def full_base_url(request, page)
          base_url = "http://#{request.subdomains.first + '.' if request.subdomains && !request.subdomains.first.nil?}#{request.domain}"
          page_url ||= parent_archive_page?(page) ? "#{page.slug ? page.url.gsub(/(#{page.slug}\/)/, "") : page.url}" : ""
          parent_page_url = page.parent && !parent_archive_page?(page) ? page.parent.url : ""
          return full_url = base_url + parent_page_url + page_url
        end
        
        def parent_archive_page?(page)
          unless page.parent.nil? || page.parent.class_name.nil?
            page.parent.class_name == "ArchivePage"
          else
            false
          end
        end
        
        def include_page_origin_assets
          include_stylesheet('admin/page_origin')
          include_javascript('admin/page_origin')
        end
      end
    
    end
  end
end