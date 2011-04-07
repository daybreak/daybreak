module Googlize # used to extend Event model with Google integrations
  def self.included(base)
    puts 'Warning: Googlized Events' unless ENV['RAILS_ENV'] == 'production'
    base.class_eval do
    	unless self.instance_methods.include? 'simple_save'
				alias :simple_save 		:save
				alias :save 					:extended_save
				alias :simple_destroy :destroy
				alias :destroy 				:extended_destroy
    	end
    end
  end

	def break_google_assoc
		self.google_event_id = nil
		self.google_event_version = nil
	end

	def extended_save
		if self.confirmed?
			self.push
			self.simple_save
			self.push
		else #only "confirmed" events remain on the google calendar
			if self.google_event_id
				self.to_google_event.destroy!
				self.break_google_assoc
			end
			self.simple_save
		end
	end

	def extended_destroy
		destroyed = false
		begin
			self.to_google_event.destroy! if self.google_event_id
			destroyed = self.simple_destroy
		rescue Net::HTTPNotFound
			destroyed = self.simple_destroy
		rescue
		end
		destroyed
	end

	def push
		#TODO: date comparison.  may need to create/update date nodes directly to XML.
		#TODO: specify timezone.
		#raise 'already exists in google' unless self.google_event_id.blank?
		result = nil
		if self.valid?
			if self.google_event_id
				puts "Pushing google update for #{self.class} id #{self.id}"
			else
				puts "Pushing google insert for #{self.class} id #{self.id}"
			end
			google_event = self.to_google_event
			google_event.save
			self.google_event_id = google_event.id
			self.google_event_version = google_event.version
			self.simple_save
			result = google_event
		end
		result
	end

	def self.push(args={})
		args.stringify_keys!
		events = self.find_between(args['from'],args['thru'])
		events.each do |event|
			event.push
		end
		return events.length
	end


	def google_event_id=(new_id)
		raise 'cannot change a google event id, but it may be nullified' if self[:google_event_id] and new_id and self[:google_event_id] != new_id
		self[:google_event_version] = nil if new_id.blank?
		self[:google_event_id] = new_id
	end

	def to_google_hash #use google attribute names
		{:title => self.name, :start_time => self.start_at, :end_time => self.end_at, :content => self.content, :author_name => (self.created_by.name rescue nil), :author_email => (self.created_by.email rescue nil), :where => self.location, :calendar => self.calendar, :status => self.event_status}
	end

	def content
		desc = []
		desc << self.body
		desc << "<b>setup:</b> #{self.start_setup_at.strftime('%I:%M %p')}" if self.has_setup?
		desc << "<b>teardown:</b> #{self.end_teardown_at.strftime('%I:%M %p')}" if self.has_teardown?
		desc << "" if self.id
		desc << "<a href='#{self.edit_url}'>edit</a>" if self.id
		desc.join("<br/>")
	end

	def to_google_event
		if self.google_event_id
			original_version = self.google_event_version
			google_event = self.fetch_google_event	#make sure we have the latest 'version'
			puts 'the record was modified at google' if google_event and original_version != google_event.version
		end
		if google_event
			google_event.parse_hash(self.to_google_hash) #apply the latest attributes
		else
			google_event = self.create_google_event
		end
		google_event
	end

	def fetch_google_event(break_assoc=true)
		google_event = nil
		begin
			if self.google_event_id
				google_event = Google::Event.find(self) #Google::Event.new(resp) unless resp.kind_of? HTTPNotFound
				#google_event = Google::Event.find('id'=>self.google_event_id,'calendar'=>EventCategory.find(self.event_category_id_was).name) #Google::Event.new(resp) unless resp.kind_of? HTTPNotFound
			end
		rescue Exception => e
			if e.to_s == "404 \"Not Found\""
				puts "Unable to find google event #{self.google_event_id}:#{self.google_event_version}; breaking association."
				self.break_google_assoc if break_assoc
			else
				raise e
			end
		end
		google_event
	end

	def calendar
		EventCategory.find(:first, :conditions => ['id = ?', self.event_category_id]).name rescue nil
	end

	def calendar=(event_category_name)
		self.event_category_id = (EventCategory.find(:first, :conditions => ['name = ?', event_category_name]) rescue nil)
		calendar
	end

	def create_google_event
		Google::Event.new(self.to_google_hash)
	end
end

