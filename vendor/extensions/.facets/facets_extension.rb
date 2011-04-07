class FacetsExtension < Radiant::Extension
  version "0.5"
  description "Mix attributes into pages (storing the attributes in a separate table)"
  url ""

  def activate
    Facets.include_assets
    Admin::PagesController.class_eval do
      before_filter do |c|
        c.include_javascript 'jquery-1.3.2'
        c.include_javascript 'jquery-no-conflicts'
      end
    end
    admin.pages.edit.add :extended_metadata, "meta"
    admin.pages.edit.add :form, "header" #, :before => 'edit_page_parts'
    admin.pages.edit.add :parts_bottom, "footer", :before => 'edit_layout_and_type'
  end
end

#TODO: implement add/remove part
#TODO: optional facets
#TODO: separate jQuery plugin to make collapsable fieldsets
#TODO: auto-open collapsed sections if error contained
#TODO: implement default value (on new records) and description from page factory; call default and hint?
#TODO: transpose input to active record model using facets??
#TODO: use outfielder as a local gem
#TODO: create rake tasks for final version (use symlinking?)

#SOMEDAY: extract into a basic ActiveRecord pattern that's not about proxied facets, but presentation meta

