module Google
	class Event
		def to_xs(xml) #TODO: put into module for inclusion
			if xml.respond_to? :body #is this an html response?
				response = xml
				xml = response.body
			end
			XmlSimple.xml_in(xml)
		end

		attr_reader :simple, :id, :version, :edit_link, :editable, :who_name, :who_email, :start_time, :end_time, :calendar
		attr_accessor :published, :updated, :title, :where, :content, :author_name, :author_email, :status

		@@extended_props ||= []
		@@client ||= Google::CalendarClient.instance

		def initialize(hash_or_http_resp_or_xml)
			@calendar = nil
			if hash_or_http_resp_or_xml.kind_of? Hash
			  parse_hash(hash_or_http_resp_or_xml)
			elsif hash_or_http_resp_or_xml.respond_to? :body
			  parse_xml(hash_or_http_resp_or_xml.body)
			else
				parse_xml(hash_or_http_resp_or_xml)
			end
		end

		def self.extended_props
			@@extended_props
		end

		def self.extended_prop(value)
			return if @@extended_props.include? value
			attr_accessor value
			@@extended_props << value
		end

		def start_time=(value)
			@start_time = nil
			@start_time = Time.parse(value.to_s) if value
		end

		def end_time=(value)
			@end_time = nil
			@end_time = Time.parse(value.to_s) if value
		end

		def self.login(email, password)
			@@client.login(email, password, true)
		end

		def self.find(id_or_params)
			if id_or_params.respond_to? :google_event_id and id_or_params.respond_to? :calendar
				params = {:id => id_or_params.google_event_id, :calendar => id_or_params.calendar}
			elsif id_or_params.kind_of? Hash
				params = id_or_params
			else
				params = {:id => id_or_params}
			end
			params.stringify_keys!
			params['calendar'] ||= 'default'
			raise 'cannot find: calendar parameter was missing' unless params.include? 'calendar'
			@@client.select_calendar params['calendar']
			puts "working with calendar #{@@client.calendar.to_s}"
			id = params['id']
			if id
				puts 'finding by id ' + id.to_s
				resp = @@client.get_event(id)
				resp.error! unless resp.kind_of? Net::HTTPOK
				result = Google::Event.new(resp)
			else
				puts 'finding with params'
				resp = @@client.get_events(params)
				resp.error! unless resp.kind_of? Net::HTTPOK
				xml = resp.body
			  doc = REXML::Document.new(xml)
			  events = []
			  doc.elements.each('//entry') do |event|
			  	events << Google::Event.new(event.to_s)
			  end
				result = events
			end
		end

		def save
			raise 'this event cannot be edited/saved' unless @editable
			if self.id
				resp = @@client.update_event(self.edit_link, self.to_xml)
				resp.error! unless resp.kind_of? Net::HTTPOK
			else
				@@client.select_calendar @calendar
				resp = @@client.add_event(self.to_xml)
				resp.error! unless resp.kind_of? Net::HTTPCreated
			end
			self.parse_xml(resp.body)
			self
		end

		# this might be called to make sure we have the latest version property
		def refresh
			original_version = @version
			if self.id
				resp = @@client.get_event(self.id)
				resp.error! if resp.kind_of? Net::HTTPNotFound
			else
				raise 'only existing events can be refreshed'
			end
			parse_xml(resp.body)
			has_change_occurred = original_version != @version
		end

		def destroy!
			raise 'this event cannot be deleted' unless @editable
			@@client.delete_event(self.edit_link)
		end

	#TODO: add reminder support
		def to_xml
			raise "missing required attributes" unless @title and @start_time and @end_time
			if @author_name and @author_email
					author_xml = "<author><name>#{@author_name}</name><email>#{@author_email}</email></author>"
			else
					author_xml = ""
			end

			props = []

			@@extended_props.each do |prop|
				value = eval("@#{prop.to_s}")
				props << "<gd:extendedProperty name=\"#{prop.to_s}\" value=\"#{value}\" />"
			end

#TODO: build with an XML Builder

			xml = <<EOF
<?xml version="1.0"?>
<entry xmlns='http://www.w3.org/2005/Atom' xmlns:gd='http://schemas.google.com/g/2005'>
	<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2005#event'></category>
	<title type='text'>#{@title.gsub('&','&amp;')}</title>
	<content type='text'><![CDATA[#{@content}]]></content>
	#{author_xml}
	<gd:transparency value='http://schemas.google.com/g/2005#event.opaque'></gd:transparency>
	<gd:eventStatus value='http://schemas.google.com/g/2005#event.#{@status}'></gd:eventStatus>
	<gd:where valueString='#{@where.to_s.gsub('&','&amp;')}'></gd:where>
	<gd:when startTime='#{@start_time.iso8601}' endTime='#{@end_time.iso8601}'>
	</gd:when>
	#{props.join('')}
</entry>
EOF
		end

		def compare(event)
			updated_at = event.updated_at || event.created_at
			if self.id == event.google_event_id
				  if self.version == event.google_event_version
				      state = :synchronized # ahh... harmony.
				  elsif updated_at.blank? or self.updated.blank?
				      raise 'missing date information'
				  elsif self.updated > updated_at
				      state = :fresher # update local with google event
				  elsif self.updated < updated_at
				      state = :stale # update google with local event
				  else
				      state = :unchanged # it's odd that the dates match but not the id/version
				  end
			else
				  raise 'cannot compare to this event'
			end
			state
		end

		def parse_hash(hash) #for a new google event
			hash.stringify_keys!
			@id = hash['id'] if hash.include? 'id'
			@version = hash['version'] if hash.include? 'version'
			@editable = true
			@calendar = hash['calendar'] || :default
			#raise 'must specify a calendar' unless calendar
			raise 'invalid calendar specified' unless @@client.calendars.include? calendar
			duration = hash['duration'] # specified in minutes
			@edit_link ||= @@client.calendars[calendar]
			@title = hash['title']
			self.start_time = hash['start_time']
			self.end_time =  hash['end_time'] if hash.include? 'end_time'
			raise 'cannot specify both duration and end_time' if @end_time and duration
			self.end_time = @start_time + (duration * 60) if duration
			@where = hash['where']
			@content = hash['content']
			@author_name = hash['author_name']
			@author_email = hash['author_email']
			@status = hash['status']

			@@extended_props.each do |prop|
				prop_value = eval("hash['#{prop.to_s}']")
				eval("@#{prop.to_s} = prop_value.blank? ? nil : prop_value")
			end

			@who_name = nil
			@who_email = nil
			@recurring = false
			raise 'missing required event attributes' unless @title and @start_time and @end_time
			raise 'the end time cannot preceed the start time' if @end_time < @start_time
		end

		def parse_xml(xml) #for an existing google event
		#TODO: determine calendar (convert to hash key name)
			@simple = to_xs(xml)
			@id = @simple['id'].first.split('/').last
			begin
				@edit_link = @simple["link"].select{|link| link["rel"] == "edit"}.first["href"]
				nodes = @edit_link.split('/')
				@version = nodes.pop
				@editable = true
			rescue
				@editable = false
			end
			@title = @simple["title"][0]["content"]
			self.start_time =  @simple["when"][0]["startTime"] rescue nil
			self.end_time =  @simple["when"][0]["endTime"] rescue nil
			@where = @simple["where"][0].values.first rescue nil
			@content = @simple["content"]["content"] rescue nil
			@author_name = @simple["author"][0]["name"][0] rescue nil
			@author_email = @simple["author"][0]["email"][0] rescue nil
			@recurring = @simple.include? 'recurrence'
			@who_name = @simple["who"][0]["valueString"] rescue nil
			@who_email = @simple["who"][0]["email"] rescue nil
			@published = Time.parse(@simple["published"][0])
			@updated = Time.parse(@simple["updated"][0])
			@status = @simple['eventStatus'][0]['value'].split('.').last
			extended_properties = @simple["extendedProperty"]

			if extended_properties.kind_of? Array
				extended_properties.each do |prop|
					prop_name  = prop['name']
					prop_value = prop['value']
					eval("@#{prop_name} = prop_value.blank? ? nil : prop_value")
				end
			end

		end
	end
end

