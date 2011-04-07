class MembersExtension < Radiant::Extension
  version "0.1"
  description "Provides the management of people and small groups for churches."
  url ""

  define_routes do |map|
		map.directory            'directory/:action/:id'            , :controller => 'persons'
		map.groups               'groups/:action/:id'               , :controller => 'groups'
		map.admin_directory      'admin/directory/:action/:id'      , :controller => 'admin/persons'
		map.admin_contact_type   'admin/contact_types/:action/:id'  , :controller => 'admin/contact_types'
		map.admin_contact_option 'admin/contact_options/:action/:id', :controller => 'admin/contact_options'
		map.admin_position       'admin/positions/:action/:id'      , :controller => 'admin/positions'
		map.admin_group          'admin/groups/:action/:id'         , :controller => 'admin/groups'
		map.admin_group_meeting  'admin/group_meetings/:action/:id' , :controller => 'admin/group_meetings'
  end

  def activate
    Radiant::Config['members.group.enrollment_notice_emails'] ||= "info@daybreakweb.com"
    Radiant::Config['members.person.change_notice_emails']    ||= "info@daybreakweb.com"
    
    tab "Directory" do
      add_item "People", "/admin/directory"    
      add_item "Groups", "/admin/groups"
      add_item "Positions", "/admin/positions"
      #TODO: add_item "Contact Types", "/admin/contact_options"
      #TODO: add_item "Contact Options", "/admin/contact_options"
    end    
    
		User.has_many :created_groups, :class_name => 'Group' , :foreign_key => 'created_by'
	  User.has_many :updated_groups, :class_name => 'Group' , :foreign_key => 'updated_by'
		User.has_many :created_people, :class_name => 'Person', :foreign_key => 'created_by'
		User.has_many :updated_people, :class_name => 'Person', :foreign_key => 'updated_by'
		User.has_many :created_group_meetings, :class_name => 'GroupMeeting', :foreign_key => 'created_by'
		User.has_many :updated_group_meetings, :class_name => 'GroupMeeting', :foreign_key => 'updated_by'
		User.belongs_to :person #, :dependent => :nullify #TODO: nullify no longer supported?
		User.send :include, Members::User
  end
end

