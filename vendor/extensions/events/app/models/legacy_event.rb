class LegacyEvent < ActiveRecord::Base
  set_table_name 'events'

  include FileColumnHelper

	STATUSES = ["confirmed","pending", "declined", "canceled"]

	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
	belongs_to :recurrence
  belongs_to :event_category
  has_and_belongs_to_many :resources, :join_table => :events_resources, :foreign_key => :event_id
	has_many :registrations, :foreign_key => :event_id, :order => 'updated_at DESC, created_at DESC'

	validates_presence_of :name
	validates_presence_of :start_at
	validates_presence_of :end_at
	validates_presence_of :event_category_id
	validates_presence_of :contact_name,         :if => Proc.new {|event| event.pending? || event.requested?}
	validates_presence_of :contact_email,        :if => Proc.new {|event| event.pending? || event.requested?}
	validates_presence_of :contact_phone,        :if => Proc.new {|event| event.pending? || event.requested?}
	validates_presence_of :contact_full_address, :if => Proc.new {|event| event.pending? || event.requested?}
	validates_presence_of :expected_attendance,  :if => Proc.new {|event| event.pending? || event.requested?}

	validates_numericality_of :setup_minutes,    :only_integer => true, :greater_than => 0, :if => Proc.new {|event| event.setup_minutes}
	validates_numericality_of	:teardown_minutes, :only_integer => true, :greater_than => 0, :if => Proc.new {|event| event.teardown_minutes}

	file_column :image, :magick => { :geometry => "900x700", :versions => { "form" => "300x300", "standard" => "400x593" } }
	file_column :invitation_image, :magick => { :geometry => "400x600"}
	#has_timezone :fields => [:start_at, :end_at, :created_at, :updated_at]

  @@filtered_event_categories = []

	def requested?
		!access_key.nil?
	end

	def continuing_events
		continuing = []
		beginning = self.start_at
		aname = self.alternate_name
		begin
			cevents = Event.find(:all, :continuing_events, :conditions => ['alternate_name = ? AND start_at > ? AND start_at <= ? AND recurrence_id IS NULL', aname, beginning, beginning + 60.days], :order => 'start_at')
			continuing << cevents
			beginning = cevents.last.start_at	unless cevents.length == 0
		end until cevents.length == 0
		continuing.flatten
	end

  def self.filtered_event_categories
    @@filtered_event_categories
  end

  def self.filtered_event_categories=(ary)
    @@filtered_event_categories = ary
  end

	def days_duration
		(Date.parse(self.end_at.strftime('%m/%d/%Y')) - Date.parse(self.start_at.strftime('%m/%d/%Y'))).to_i
	end

  def adjust_date(date)
    date = Date.parse(date.to_s) unless date.kind_of? Date
  	days = self.days_duration
		self.start_at = Time.parse(date.to_s + ' ' + self.start_at.strftime('%I:%M %p'))
		self.end_at   = Time.parse((date + days).to_s + ' ' + self.end_at.strftime('%I:%M %p'))
		self
  end

	def edit_url
		"#{Radiant::Config['org.root_url']}/admin/events/edit/#{self.id}"
	end

	def image_url(options = nil)
    url_for_file_column(self, "image", options)
  end

	def invitation_image_url(options = nil)
    url_for_file_column(self, "invitation_image", options)
  end

	def num_children
		num = 0
		registrations.each { |r| num += r.children unless r.children.blank? }
		num
	end

	def num_adults
		num = 0
		registrations.each { |r| num += r.adults unless r.adults.blank? }
		num
	end

	def event_status
	  self.status
	end

	def confirmed?
		self.status == 'confirmed'
	end

	def canceled?
		self.status == 'canceled'
	end

	def pending?
		self.status == 'pending'
	end

	def declined?
		self.status == 'declined'
	end


	def num_registrants
		num = 0
		registrations.each do |r|
			num += r.adults   unless r.adults.blank?
			num += r.children unless r.children.blank?
		end
		num
	end

	def mailing_list
		registrations.collect{|registrant| registrant.contact_email}
	end

	def has_space?
		if num_open_spots
			num_open_spots > 0
		else
			true
		end
	end

	def describe_space
		num_open_spots ? (num_open_spots == 0 ? "full" : num_open_spots.to_s + " spots left!") : "unlimited spots!"
	end

	def taking_registrations?
		has_space? and confirmed?
	end

	def title
		name.include?(':') ? name.split(':')[0].strip : name
	end

	def subtitle
		alternate_name # || (name.include?(':') ? name.split(':')[1].strip : name)
	end

	def has_setup?
		!self.setup_minutes.blank? and self.setup_minutes > 0
	end

	def has_teardown?
		!self.teardown_minutes.blank? and self.teardown_minutes > 0
	end

	def starred?
		self.starred
	end

	def confidential_attendance?
		self.confidential_attendance
	end

	def start_setup_at
		self.start_at - (60 * (self.setup_minutes || 0))
	end

	def end_teardown_at
		self.end_at + (60 * (self.teardown_minutes || 0))
	end

	# returning: nil = no limit, 0 = full, n = number of spots left
	def num_open_spots
		open = capacity - num_registrants if capacity
		open = 0 if open and open < 0
		open
	end

	def happened?
		start_at < Time.now
	end

	def self.with_invitations
		self.find(:all, :conditions => ["start_at between ? and ? and invitation is not null and status = 'confirmed'", Time.now, 60.days.from_now])
	end

	def self.find_thru(date)
		self.find_between(Date.today, date)
	end

	def self.find_since(date = Time.today)
		self.find_between(date, nil)
	end

	def self.find_recent_edits(minutes=720)
		self.find(:all, :conditions => ["updated_at >= ?", minutes.minutes.ago], :order => 'updated_at DESC')
	end

	def self.has_status(status)
		self.count_status(status) > 0
	end

	def self.count_status(status)
		self.count(:all, :conditions => ["status = ?", status])
	end

	#used primarily for filtering "pending" requests.
	def self.find_by_status(status)
		self.find(:all, :conditions => ["status = ?", status], :order => 'start_at DESC')
	end

	def self.find_between(from = Date.today, thru = nil)
		values = {}
		values[:f] =  from.kind_of?(String) ? Date.parse(from) : from
		values[:t] = (thru.kind_of?(String) ? Date.parse(thru) : thru).end_of_day
		values[:c] = self.filtered_event_categories unless self.filtered_event_categories.empty?
		cond = []
		cond << "start_at >= :f" if values[:f]
		cond << "start_at <= :t" if values[:t]
		cond << "event_category_id IN (:c)" if values[:c]
		conditions = [cond.join(' AND '), values] if cond.length > 0
    self.find(:all, :conditions => conditions, :order => "start_at, id")
	end
end

