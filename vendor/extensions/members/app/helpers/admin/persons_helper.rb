module Admin::PersonsHelper
  include Markaby::Rails::ActionControllerHelpers
	include MarkupHelpers::Toggles
	include MarkupHelpers::TabControl
	include MarkupHelpers::Radiant
	include MarkupHelpers::AuthenticityToken

  def format_name(person)
    style_person = ['title']
    style_person << 'canceled' unless person.active?
    style_person = style_person.join(' ')
    markaby do
      span :class => style_person do
        text person.file_as
      end
    end
  end

  def search_options
    include_stylesheet 'form/search_options'
    markaby do
      div.search_options! do
        yield
      end
    end
  end

  def person_icon
    image_tag("/images/admin/person.png", :align => 'center', :alt => 'page-icon', :class => 'icon')
  end

  def searching
    params[:action] == 'search'
  end

  def person_link(person)
    link_to("#{person_icon} #{format_name(person)}", :controller => '/admin/persons', :action => 'edit', :id => person)
  end

  def identify
    markaby do
      span.w1 do
        yield
      end
    end
  end

  def mod_links(row_id, person, group, position)
    add_image = image_tag("/images/admin/add.png", :alt => "Add")
    remove_image = image_tag("/images/admin/remove.png", :alt => "Remove")
    if group
      target_obj = group
      use_controller = '/admin/groups'
      target_thing = 'member'
      target_div = 'member_list'
    elsif position
      target_obj = position
      use_controller = '/admin/positions'
      target_thing = 'subordinate'
      target_div = 'supervised_list'
    end
    if target_obj
      add      = link_to_remote(add_image   , :update => target_div, :url => {:controller => use_controller, :action => "add_#{target_thing}"   , :id => target_obj.id, :person_id => person.id}, :success => visual_effect(:fade, row_id), :failure => visual_effect(:highlight, row_id))
      remove   = link_to_remote(remove_image, :update => target_div, :url => {:controller => use_controller, :action => "remove_#{target_thing}", :id => target_obj.id, :person_id => person.id})
    end
    remove = "Already Added" if searching
    if target_obj
      target_obj.people.include?(person) ? remove : add
    else
      ''
    end
  end
end

