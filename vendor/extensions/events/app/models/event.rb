class Event < Page
	STATUSES = ["confirmed", "pending", "declined", "canceled"]
	
  include FileColumnHelper
  file_column :image, :magick => { :geometry => "900x700", :versions => { "form" => "300x300", "standard" => "400x593" } }
  file_column :invitation_image, :magick => { :geometry => "400x600"}  

  def Event.requested?
    Proc.new{|page| page.requested?}
  end

  belongs_to :event_category
  has_and_belongs_to_many :resources, :join_table => 'pages_resources', :foreign_key => :page_id
	belongs_to :recurrence
	has_many :registrations, :class_name => 'Registration', :foreign_key => :page_id, :order => 'updated_at DESC, created_at DESC'

  validates_presence_of :start_at
  validates_presence_of :end_at
  validates_presence_of :event_category_id

  validates_numericality_of :setup_minutes,    :only_integer => true, :greater_than => 0, :if => Proc.new {|event| event.setup_minutes}
  validates_numericality_of	:teardown_minutes, :only_integer => true, :greater_than => 0, :if => Proc.new {|event| event.teardown_minutes}

	validates_presence_of :expected_attendance,  :if => Event.requested?
  validates_presence_of :contact_name,         :if => Event.requested?
  validates_presence_of :contact_email,        :if => Event.requested?
  validates_presence_of :contact_phone,        :if => Event.requested?
  validates_presence_of :contact_full_address, :if => Event.requested?

	#TODO: sync status_id of page with event_status using before_save filter.
	def after_initialize
		if self.new_record?
    	self.body ||= nil #for instantiation of part
    	self.status_id  = 100
		end
	end
	
	def name
	  title
	end
	
	def copy
    attrs = attributes
	  
	  attrs.delete('id')
	  attrs.delete('image')
	  attrs.delete('invitation_image')
	  attrs.delete('created_at')
	  attrs.delete('created_by')
	  attrs.delete('updated_at')
	  attrs.delete('updated_by')
	  
	  copied = Event.new(attrs)
	  copied.body = body
	  copied.resource_ids = resource_ids
	  copied
	end

	#TODO: move access_key + generate_key into its own extension -- available to all pages upon creation
	def requested?
		!access_key.nil?
	end

	def subtitle
		alternate_name || (name.include?(':') ? name.split(':')[1].strip : name)
	end

  #TODO: create a macro for adding part attributes
	def body
	  parts.detect{|part| part.name == 'body'}.try(:content)
	end

	def body=(text)
	  p = parts.detect{|part| part.name == 'body'} || parts.build(:name => 'body')
  	p.content = text
	end

	def edit_url
		"#{Radiant::Config['org.root_url']}/admin/events/edit/#{self.id}"
	end

  #TODO: before_update :drop_former_event ??
  def drop_former_event
    if self.event_category_id_changed?
      parent = self.page
      puts "Calendar changed on #{parent.class} #{parent.id}"
      ge = parent.fetch_google_event(false)
      puts "-"*90
      puts ge.inspect
      puts "="*90
      ge.destroy! if ge #prevents an error when updating a canceled event
      self.google_event_id = nil
    end
  end

	#TODO: refactor how continuing events are handled.
	def continuing_events
		continuing = []
		if self.alternate_name
  		beginning = self.start_at
		  begin
			  cevents = Event.all(:conditions => ['alternate_name = ? AND recurrence_id IS NULL AND start_at > ? AND start_at <= ?', self.alternate_name, beginning, beginning + 60.days], :order => 'start_at')
			  continuing << cevents
			  #rexecute the query to handle the chaining of continued events which might otherwise fall outside the 60-day window
			  beginning = cevents.last.start_at	unless cevents.length == 0
		  end until cevents.length == 0
		end
		continuing.flatten
	end

	def image_url(options = nil)
    url_for_file_column(self, "image", options)
  end

	def invitation_image_url(options = nil)
    url_for_file_column(self, "invitation_image", options)
  end

  def confirmed?
    event_status == 'confirmed'
  end

  def canceled?
    event_status == 'canceled'
  end

  def pending?
    event_status == 'pending'
  end

  def declined?
    event_status == 'declined'
  end

	def has_setup?
		!setup_minutes.blank? and setup_minutes > 0
	end

	def has_teardown?
		!teardown_minutes.blank? and teardown_minutes > 0
	end

	def start_setup_at
		start_at - (60 * (setup_minutes || 0))
	end

	def end_teardown_at
		end_at + (60 * (teardown_minutes || 0))
	end

	def happened?
		start_at < Time.now
	end

	def starred?
		starred
	end

	def days_duration
		(Date.parse(end_at.strftime('%m/%d/%Y')) - Date.parse(start_at.strftime('%m/%d/%Y'))).to_i
	end

	def adjust_date(date)
		date = Date.parse(date.to_s) unless date.kind_of? Date
		days = days_duration
		self.start_at = Time.parse(date.to_s + ' ' + self.start_at.strftime('%I:%M %p'))
		self.end_at   = Time.parse((date + days).to_s + ' ' + self.end_at.strftime('%I:%M %p'))
		self
	end
	
  def num_children
    registrations.inject(0){|sum, r| sum + (r.children || 0)} rescue nil
  end

  def num_adults
    registrations.inject(0){|sum, r| sum + (r.adults || 0)} rescue nil
  end

  def num_registrants
	  registrations.inject(0){|sum, r| sum + (r.adults || 0) + (r.children || 0)} rescue nil
  end
  
  def registration_open?
    open = true
    open = Time.now >= registration_start_at if registration_start_at && open
    open = Time.now <= registration_end_at   if registration_end_at   && open
    open
  end

  def mailing_list
	  registrations.map{|registrant| registrant.contact_email}.uniq
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
	  has_space? && confirmed?
  end

  # returning: nil = no limit, 0 = full, n = number of spots left
  def num_open_spots
	  open = capacity - num_registrants if capacity
	  open = 0 if open and open < 0
	  open
  end

	def self.find_recent_edits(minutes=720)
		self.find(:all, :conditions => ["class_name = '#{self}' AND updated_at >= ?", minutes.minutes.ago], :order => 'updated_at DESC')
	end

	def self.find_thru(date)
		self.find_between(Date.today, date)
	end

	def self.find_since(date = Time.today)
		self.find_between(date, nil)
	end

	def self.find_by_status(status) #used primarily for filtering "pending" requests.
		self.all(:conditions => ["event_status = ?", status], :order => 'start_at DESC')
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
		self.all(:conditions => conditions, :order => "start_at, id")
	end

	def self.has_status(status)
		self.count_status(status) > 0
	end

	def self.count_status(status)
		self.count(:conditions => ["event_status = ?", status])
	end
	
	@@filtered_event_categories = []

	def self.filtered_event_categories
		@@filtered_event_categories
	end

	def self.filtered_event_categories=(ary)
		@@filtered_event_categories = ary
	end
	
	def self.sluggify(events)
		events = [*events]
		events.each do |event|
		  new_slug = event.id.to_s + "-#{self.to_slug(event.title)}"
		  unless event.slug == new_slug
  			event.slug = new_slug
	  		event.save
	  	end
		end
	end

	def self.to_slug(text)
		text = text.downcase
		out = []
		text.each_char do |c|
			letter = c =~ /[a-z]/i
			out << (letter ? c : ' ')
		end
		out.join.squeeze(" ").strip.gsub(' ', '-')
	end
	
	def validate
		super
		backout_error do |record, error|
			force_to_blank = [:slug, :breadcrumb].include?(error.attribute.to_sym) 
			force_to_blank & record.parent_id.nil? && record.send(error.attribute).nil?
		end
	end

  #TODO: extract and publish
	#inspired by: http://stackoverflow.com/questions/2309757/removing-or-overriding-an-activerecord-validation-added-by-a-superclass-or-mixin
	def backout_error
		errs = errors.instance_variable_get(:@errors)
		backed_out = []
		remove_keys = []
		errs.each do |key, value|
		  removes = []
		  if value.is_a? Array
		    removes = value.select{|error| yield(error.base, error)}
		    removes.each{|error|value.delete(error)}
		    remove_keys << key if errs[key].length == 0
		    backed_out << removes
		  elsif yield(error.base, error)
  		  remove_keys << key 
  		  backed_out << error
		  end
		end
		remove_keys.each{|key| errs.delete(key)}
		backed_out.flatten
	end
	
end

