class Person < ActiveRecord::Base
	include ActionView::Helpers::UrlHelper
	include ActionView::Helpers::TagHelper
  include FileColumnHelper
  validates_presence_of :first_name, :last_name, :gender
  has_many :group_members, :dependent => :destroy
  has_many :groups, :through => :group_members
  has_and_belongs_to_many :group_meetings
  has_one :user, :dependent => :nullify
  belongs_to :primary_contact_option, :class_name => 'ContactOption', :foreign_key => :primary_contact_option_id
  has_many   :contact_options, :order => "created_at", :dependent => :destroy
  has_many   :positions, :dependent => :destroy
  belongs_to :person_type
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
	after_save :send_change_notice
 	file_column :photo, :magick => { :geometry => "640x480",  :versions => {
 												:thumb => {:crop => "4:3", :size => "100x75", :name => "thumb"},
 												:small => {:crop => "4:3", :size => "200x150", :name => "small"},
 												}
 											}

	PRIVACY_LEVELS = ["Keep my info. private","Show my info. to my small group only","Show my info. to church members","Show my info. to regular attenders", "Show my info. to everyone"]

	def full_address(include_name = true)
		out = []
		out << full_name if include_name
		out << address if address && address.size > 0
		out << "#{city}, #{state}  #{zip}" unless city.blank? and state.blank?
		out
	end

	def share_info_with(user)
		return privacy_level == 4 unless user
		return true if user.person == self #I can always see my own info.
		return true if user.backend_access?
		case privacy_level
			when 0
				false
			when 1
				in_small_group(user.person)
			when 2
				(user.person.person_type_id == 1 or user.person.person_type_id == 2 if user.person) || false
			when 3
				(user.person.person_type_id == 1 or user.person.person_type_id == 2 or user.person.person_type_id == 3 if user.person) || false
			when 4
				true
			else
				false
		end
	end

	def anonymous
		(gender == "M" ? "Male" : "Female") + " <small>(private)</small>"
	end

	def in_small_group(another_person)
		self.groups.each{|group| group.people.each{|person| return true if person == another_person}} if another_person
		false
	end

	def summary
		(person_type.name if person_type) || "{type not specified}"
	end

	def supervisors
		subordinates = Subordinate.find(:all, :conditions => ["person_id = ?", id])
		subordinates.collect{|subordinate| subordinate.position}
	end

  def photo_url(options = nil)
    url_for_file_column(self, "photo", options)
  end

	#even apprentice leaders are considers leaders for administrative purposes.
	def leader?
		self.group_members.each{|m| return true if m.group_role_id == 1 or m.group_role_id == 5}
		return false
	end

	def member?
		self.person_type_id < 3
  end

	def registered?
		!self.external_id.blank?
  end

	def directory_access?
		self.person_type_id <= 2
  end

	def active?
		self.active
	end

	def full_name
		self.first_name + ' ' + self.last_name
	end

	def file_as
		self.last_name + ', ' + self.first_name
	end

	def primary_contact_option_defaulting(contact_option)
		if primary_contact_option_id.blank?
  		primary_contact_option_id = contact_option.id
  		save
		end
	end

	def email
		option = ContactOption.find(:first, :conditions => ["person_id = ? and contact_type_id = 1", id])
		option ? option.contact_info : nil
	end

	def phone_numbers
		contact_options.select {|co| co.contact_type.code == "H" or co.contact_type.code == "W" or co.contact_type.code == "M"}.collect {|co| fmt_contact_option(co)}
	end

	def contact_info
		contact_options.collect{|co| fmt_contact_option(co)}
	end

  #this is useful as an interface so that both User and Person can return Person.
  def person
    self
  end

	def self.find_latest_additions
		self.find(:all, :order => 'created_at desc',  :limit => 5)
	end

	def self.find_group_orphans
		self.find(:all, :conditions => ["active = 1 and id not in (select person_id from group_members)"], :order => 'last_name, first_name')
	end

	def self.find_by_params(params)
  	if params[:position_id]
  		Subordinate.find(:all, :conditions => ["position_id = ?", params[:position_id]]).collect{|subordinate| subordinate.person }
  	elsif params[:group_id]
  		@group = Group.find(params[:group_id])
  		@group.group_members
		else
			conditions = []
			name_start = h(params[:name_start])
			if !name_start.blank?
				raise Exceptions::InsufficientCriteria unless name_start.size > 2
				conditions << "(last_name LIKE \"#{name_start}%\" OR first_name LIKE \"#{name_start}%\")"
			elsif !params[:name_start_letter].blank?
				conditions << "last_name LIKE \"#{params[:name_start_letter]}%\""
			end
			conditions << "person_type_id <= #{params[:person_type_id]}"       unless params[:person_type_id].blank?
			conditions << "MONTH(born_on) = #{params[:birth_month]}"          unless params[:birth_month].blank?
			conditions << "active = #{params[:active] == 'Yes' ? 1 : 0}"      unless params[:active].blank?
			conditions << "(id " + (params[:small_group] == "Yes" ? "IN" : "NOT IN") + " (SELECT person_id FROM group_members))" unless params[:small_group].blank?
			order = []
			order << "DAY(born_on)" unless params[:birth_month].blank?
			order << "last_name"
			order << "first_name"
			if conditions.any?
				Person.find(:all, :conditions => conditions.join(" AND "), :order => order.join(", "))
			else
				[]
			end
  	end
	end

	def set_defaults
    self.person_type_id = 5
    self.gender = "M"
	end

private

	def self.save_contact_options(person, params)
		return unless params[:contact_option]
  	params[:contact_option].each do |index, contact_option|
   		unless contact_option[:contact_info].blank?
	   		co = contact_option[:id].blank? ? ContactOption.new : ContactOption.find(contact_option[:id])
				contact_option[:person_id] = person.id if co.new_record? # new contact option
	  		co.update_attributes(contact_option)
	  		unless person.primary_contact_option # default the primary contact information
		  		person.primary_contact_option = co
		  		person.save
	  		end
  		end
  	end
	end

	def self.save_positions(person, params)
  	params[:position].each do |index, position|
   		unless position[:position_type_id].blank?
   			id = position[:id]
				if id.blank? # new contact option
	  			position[:person_id] = person.id # link to parent
		  		created = Position.new()
		  		created.update_attributes(position)
		  	else # existing contact option
			  	Position.find(id).update_attributes(position)
		  	end
  		end
  	end
	end

	def fmt_contact_option(contact_option, bullet = true)
		if contact_option.contact_type.code =~ /[H|W|M]/
			fmt = "#{contact_option.contact_info} (#{contact_option.contact_type.code})"
		elsif contact_option.contact_type.id == 1
			fmt = mail_to(contact_option.contact_info)
		else
			fmt = contact_option.contact_info
		end
		fmt += " *" if bullet and is_primary?(contact_option)
		fmt
	end

	def is_primary?(contact_option)
		self.primary_contact_option == contact_option
	end

	def send_change_notice
		ChangeMailer.deliver_change_notice(self) if Radiant::Config['members.person.change_notice_emails'].split(";").any?
	rescue Exception => ex
	  logger.error ex.inspect
	end
end

module Exceptions
  class InsufficientCriteria < StandardError
  	def message
  		"Ignored name start.  At least 3 letters are required."
 		end
  end
end

