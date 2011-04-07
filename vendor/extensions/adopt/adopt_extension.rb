class AdoptExtension < Radiant::Extension
  version "0.5"
  description "Adds the ability to reassign the parent of a page."
  url ""

  define_routes do |map|
    map.page_adopt  'admin/pages/:id/adopt/:child_id', :controller => 'admin/pages', :action => :adopt
  end

  def activate
    admin.page.index.add :top, 'adopt'
    admin.page.index.add :sitemap_head, 'adopt_th'
    admin.page.index.add :node, 'adopt_td'
  
    Admin::PagesController.class_eval do
      def adopt
        page  = Page.find(params[:id])      
        child = Page.find(params[:child_id])
        child.parent = page 
        child.save || raise('Unable to save new parent page') #TODO: handle what would happen if this resulted in a duplicate slug.
        render :status => 200, :text => "Page #{page.url} (#{page.id}) adopted page #{child.url} (#{child.id})"
      rescue Exception => ex
        render :status => 400, :text => ["Could not adopt page", ex.inspect].join("\n")
      end
    end

  end
end
