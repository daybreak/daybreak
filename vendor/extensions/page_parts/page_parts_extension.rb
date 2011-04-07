class PagePartsExtension < Radiant::Extension
  version "0.1"
  description "Provides and overview of parts used by name"
  url ""

  define_routes do |map|
    map.admin_parts 'admin/page_parts/index/',:controller => 'admin/page_parts', :action => :index
  end

  def activate
    Admin::PagePartsController.class_eval do
      only_allow_access_to :when => [:admin,:writer,:staff],
        :denied_url => {:controller => '/admin/users', :action => :bounce}    
    
      def index
        #is_blank = 'content = '' OR content IS NULL'
        name = params[:name]
        special = params[:special]
        if special == 'blank'
          conditions = "TRIM(content) = '' OR content IS NULL"
        else
          conditions = "name IN ('#{name}')"
        end
        @filters     = PagePart.find_by_sql(["SELECT DISTINCT(name) FROM page_parts ORDER BY name"]).map{|page_part| ['name', page_part.name, PagePart.count(:conditions => "name = '#{page_part.name}'")]}
        #@filters    << ["special", "blank", PagePart.count(:conditions => is_blank)]
        @page_parts  = PagePart.all(:conditions => conditions, :include => :page, :order => 'page_id, name').select{|page_part| page_part.page}
      end
    end

    tab "Content" do
      add_item "Parts", "/admin/page_parts"
    end 
  end
end

#TODO: add pagination
#TODO: add batch part rename. e.g. hook => slogan
#TODO: add batch delete via (checkbox)
#TODO: add feature to delete all empty parts
#TODO: add feature for viewing all parts on a single page

