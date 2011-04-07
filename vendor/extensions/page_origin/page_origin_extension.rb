# Uncomment this if you reference any of your controllers in activate
require_dependency 'application_controller'

class PageOriginExtension < Radiant::Extension
  version "1.1"
  description "When you go to create or edit a page, you will now see the parent page title right under the page title text field."
  url "http://github.com/atinypixel/radiant-page-origin-extension/"

  def activate
    Admin::PagesController.send :include, Admin::PageOriginController
    admin.pages.edit.add :form, "parent_page_title", :before => "edit_page_parts"
  end

  # def deactivate
    # admin.pages.edit.remove :form, "parent_page_title"
  # end

end

