class Group < ActiveRecord::Base
	include ActionView::Helpers::UrlHelper
	include ActionView::Helpers::TagHelper
	has_many :group_meetings, :dependent => :destroy
  has_many :group_members, :dependent => :destroy
  has_many :people, :through => :group_members

  validates_presence_of :name, :meeting_frequency, :meeting_day, :meeting_time_of_day, :max_size, :group_type_id
  belongs_to :group_type
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
 	file_column :photo, :magick => { :geometry => "640x480",  :versions => {
 												:thumb => {:crop => "4:3", :size => "100x75", :name => "thumb"},
 												:small => {:crop => "4:3", :size => "200x150", :name => "small"},
 												}
 											}

	MEETING_FREQUENCIES = %w(Weekly Biweekly Bimonthly Monthly Irregular)

	def location
		out = []
		out << meeting_place if meeting_place
		out << address if address && address.size > 0
		out << "#{city}, #{state}  #{zip}" if !city.blank? or !state.blank? or !zip.blank?
		out
	end

	def men
		group_members.select{|group_member| group_member.person.gender == "M"}
	end

	def women
		group_members.select{|group_member| group_member.person.gender == "F"}
	end

  #TODO: view logic should be in helpers

	def composition(include_openings = false)
		out = []
		block_width = 4
		out << "<table class='composition-chart'>"
		out << "<tr>"
		out << "<td><label>men:</label></td>"
		out << "<td>"
		out << "<div class='bar male' style='width: #{men.size * block_width}px;'></div>" if men.size > 0
		out << men.size.to_s
		out << "</td>"
		out << "</tr>"

		out << "<tr>"
		out << "<td><label>women:</label></td>"
		out << "<td>"
		out << "<div class='bar female' style='width: #{women.size * block_width}px;'></div>" if women.size > 0
		out << women.size.to_s
		out << "</td>"
		out << "</tr>"

		top_size = 10
		if include_openings
			out << "<tr>"
			out << "<td><label>openings:</label></td>"
			out << "<td>"
			out << "<div class='bar openings' style='width: #{spots_left * block_width}px;'></div>" if spots_left and spots_left <= top_size
			out << "<div class='bar openings' style='width: #{top_size * block_width}px; text-align: right;'>...</div>" if spots_left and spots_left > top_size
			out << spots_left ? spots_left.to_s : "unlimited"
			out << "</td>"
			out << "</tr>"
		end
		out << "</table>"
		out
	end

	def coach
		unless new_record? or !leaders.any?
			ids = leaders.collect{|leader| leader.id.to_s }.join(',')
			subordinates = Subordinate.find(:all, :conditions => "person_id IN (#{ids})")
			subordinates.each{|subordinate| return subordinate.position.person if subordinate.position.position_type.title == "Coach"}
		end
		return nil
	end

	def may_change(user)
		if user.admin? or user.staff?
			true
		elsif user.leader?
			self.leaders.include?(user.person)
		else
			false
		end
	rescue
		false
	end

	def mailing_list
		group_members.collect {|gm| gm.person.email }.select{ |email| email }.uniq
	end

	def current_size
		group_members.length
	end

	def is_full?
		if max_size
			current_size >= max_size
		else
			false
		end
	end

	def slots
		out = []
		group_members.each { |gm| out << gm }
		spots_left.downto(1) { |free_slot| out << nil} if max_size 	# additional open slots
		out << nil unless max_size 																	# if unlimited-size always make sure to show one open slot
		out
	end

	def meetings
		begin
			out = []
			out << MEETING_FREQUENCIES[meeting_frequency]
			out << Date::DAYNAMES[meeting_day].pluralize
			out << meeting_time_of_day.strftime("%l:%M %p")
			out
		rescue
		end
	end

	def members
		out = []
		out << group_type.name
		out << "#{min_age} to #{max_age}" if min_age and max_age
		out << "#from {min_age}" if min_age and !max_age
		out << "to #{max_age}" if !min_age and max_age
		out << "all ages" if !min_age and !max_age
		out
	end

	def summary
		names = leader_names
		names.any? ? "Lead by #{names.join(' and ')}" : "No leader specified"
	end

	def leader_emails
		leaders.select{|leader| leader.email}.collect{|leader| leader.email}
	end

	def self.find_days
		Group.find_by_sql("SELECT DISTINCT meeting_day FROM groups ORDER BY meeting_day").collect{|group| group.meeting_day }
	end

	def self.find_times
		Group.find_by_sql("SELECT DISTINCT meeting_time_of_day FROM groups ORDER BY meeting_time_of_day").collect{|group| group.meeting_time_of_day }
	end

	def self.find_cities
		Group.find_by_sql("SELECT DISTINCT city FROM groups WHERE city IS NOT NULL ORDER BY city").collect{|group| group.city }.reject{|city| city.blank?}
	end

	def self.find_with(params)
		sql = []
		sql << "group_type_id IN (" + params[:group_type].to_a.collect{|a| a[1]}.join(",") + ")" if params[:group_type]
		sql << "city IN (" + params[:city].to_a.collect{|a| "\"" + a[1] + "\""}.join(",") + ")" if params[:city]
		sql << "meeting_frequency IN (" + params[:meeting_frequency].to_a.collect{|a| a[1]}.join(",") + ")" if params[:meeting_frequency]
		sql << "meeting_day IN (" + params[:meeting_day_of_week].to_a.collect{|a| a[1]}.join(",") + ")" if params[:meeting_day_of_week]
		sql << "meeting_time_of_day IN (" + params[:meeting_time_of_day].to_a.collect{|a| "\"" + a[1] + "\""}.join(",") + ")" if params[:meeting_time_of_day]
		sql << "( (min_age < #{params[:age]} OR min_age IS NULL) AND (max_age >= #{params[:age]} OR max_age IS NULL) )" if params[:age] and params[:age].length > 0
		sql << "provides_childcare = 1" if params[:need_child_care]
		sql << "active = true"
		if sql.any?
			groups = Group.find(:all, :conditions => sql.join(" AND "))
		else
			groups = Group.find(:all)
    end
		groups = groups.reject{|group| group.is_full?} if params[:has_room]
		groups
	end

	def enrollment_notice_emails
		(Radiant::Config['events.event_request_notice_emails'].split(";") + leader_emails).flatten.uniq
	end

	def leaders
		GroupMember.find(:all, :conditions => ["group_role_id = ? and group_id = ?", 1, id]).collect{ |m| m.person }
	end

  def leader
    leaders.first
  end

	def leader_names
		leaders.collect{|leader| leader.full_name }
	end

	def active?
		active
	end

	def spots_left
		if max_size
			max_size - group_members.count
		else
			nil
		end
	end

	def unlimited?
		max_size == nil
	end

  def contact_info
  	ci = []
  	if leaders.any?
  		leaders.each{|leader| ci << leader.contact_info}
  	end
  	ci.flatten
  end

	def email
		leaders.first.email if leaders.any? and leaders.first
	end

	def self.find_latest_additions
		self.find(:all, :order => 'created_at desc',  :limit => 5)
	end

	def add_member(someone)
    person = someone.person
		unless is_full?
			gm = GroupMember.new(:person_id => person.id, :group_id => id)
			gm.save
			gm
		else
			raise "There is no more room in this group."
		end
	end

	def remove_member(someone)
    person = someone.person
		GroupMember.find(:first, :conditions => ['person_id = ? and group_id = ?', person.id, self.id]).destroy
	end

	def belong_to?(someone)
    person = someone.person unless someone.nil?
    return nil unless person
    GroupMember.find(:first, :conditions => ['person_id = ? and group_id = ?', person.id, self.id])
	end
end

