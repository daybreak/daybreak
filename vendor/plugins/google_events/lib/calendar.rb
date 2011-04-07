module Google
	class Calendar
		def to_xs(xml) #TODO: put into module for inclusion
			if xml.respond_to? :body #is this an html response?
				response = xml
				xml = response.body   
			end
			XmlSimple.xml_in(xml)
		end
		attr_reader :simple, :id, :title, :edit_link, :version, :editable, :published, :updated, :access_level, :author_name, :author_email, :selected, :hidden, :color, :times_cleaned, :timezone, :where, :summary
		
		@@client ||= Google::CalendarClient.instance
		
		def initialize(hash_or_http_resp_or_xml)
			if hash_or_http_resp_or_xml.kind_of? Hash
			  parse_hash(hash_or_http_resp_or_xml)
			elsif hash_or_http_resp_or_xml.respond_to? :body
			  parse_xml(hash_or_http_resp_or_xml.body)
			else
				parse_xml(hash_or_http_resp_or_xml)
			end
		end

		def self.find(scope = :all)
			resp = @@client.get_calendars(scope)
	    doc = REXML::Document.new(resp.body)
	    calendars = []
	    doc.elements.each('//entry') do |calendar|
	    	calendars << Google::Calendar.new(calendar.to_s)
	    end
			result = calendars
		end

		def parse_hash(hash) #for a new google calendar
			raise 'not yet supported' #TODO: add support
		end

		def parse_xml(xml) #for an existing google calendar
			@simple = to_xs(xml)
			@timezone = @simple['timezone'][0]['value']
			@published = Time.parse(@simple['published'][0]['value'].to_s) rescue nil
			@updated = Time.parse(@simple['updated'][0]['value'].to_s) rescue nil
			@access_level = @simple['accesslevel'][0]['value']
			@author_name = @simple['author'][0]['name'][0] rescue nil
			@author_email = @simple['author'][0]['email'][0] rescue nil
			@selected = @simple['selected'][0]['value'] == 'true'
			@hidden = @simple['hidden'][0]['value'] == 'true'
			@summary = @simple['summary'][0]['content'] rescue nil
			@color = @simple['color'][0]['value']
			@times_cleaned = @simple['timesCleaned'][0]['value'].to_i
			@id = @simple['id'].first.split('/').last.gsub('%40','@')
			@where = @simple['where'][0]['valueString'] rescue :unknown
			begin
				@edit_link = @simple["link"].select{|link| link["rel"] == "edit"}.first["href"].gsub('%40','@')
				@editable = true
			rescue
				@editable = false
			end
			@title = @simple["title"][0]["content"]
		end   
		
	end
end
