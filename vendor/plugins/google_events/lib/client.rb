module Google
	module HTTPLogger
		def self.log(action, url, response, data = nil)
		  #override if logging is desired        
		end
	end

	class Client
		attr_accessor :port
		attr_reader :email, :headers, :service, :source

		DEFAULT_TRIES = 3
		ACCOUNT_TYPE = 'HOSTED_OR_GOOGLE'
		URL = "www.google.com"

		def initialize(service = nil, source = nil)
			@service = service
			@source = source
			@port = 80
		end

		def login(email, password)
			@email = email
			@password = password
			puts 'logging in'
			url = "https://#{URL}/accounts/ClientLogin"
			response = Net::HTTPS.post_form(URI.parse(url), {'Email' => email, 'Passwd' => password, 'source' => @source, 'accountType' => ACCOUNT_TYPE, 'service' => @service})
			HTTPLogger.log :post, url, response
			response.error! unless response.kind_of? Net::HTTPSuccess
			self.token = response.body.split(/=/).last
		end
		
		def token=(value)
			@token = value.chomp
			@headers = {'Authorization' => "GoogleLogin auth=#{@token}", 'Content-Type'  => 'application/atom+xml'}
		end
		
		def token
			@token
		end
		
		#used when a session has timed out.
		def reauthenticate 
			self.login(@email, @password)
		end

		def http
			Net::HTTP.new(URL, @port)
		end

		def get(url)
			service_call(url) do |url|
			  response, data = http.get(url, @headers)
			  HTTPLogger.log :get, url, response
			  [response, data]
			end
		end

		def post(url, xml)
			service_call(url) do |url|
			  response, data = http.post(url, xml, @headers)
			  HTTPLogger.log :post, url, response, xml
			  [response, data]
			end
		end

		def put(url, xml)
			service_call(url) do |url|
			  response, data = http.put(url, xml, @headers)
			  HTTPLogger.log :put, url, response, xml
			  [response, data]
			end
		end

		def delete(url)
			service_call(url) do |url|
			  response, data = http.delete(url, @headers)
			  HTTPLogger.log :delete, url, response
			  [response, data]
			end
		end

	private
	 
		def service_call(url, tries = 3)
			response = nil
			while tries > 0
				tries -= 1
				response, data = yield(url)
				if response.kind_of? Net::HTTPRedirection
					url = response['location'] 
				elsif response.kind_of? CalendarClient #
					break
					#self.reauthenticate
				else
					break
				end
			end
			response
		end

	end

	class CalendarClient < Client
		include Singleton
		attr_accessor :calendar, :visibility, :projection

		def initialize
		  super('cl', 'mlanza-GoogleEvent-v1')
		  @calendar   = '/calendar/feeds/default'
		  @visibility = 'private'
		  @projection = 'full'
		end

		def login(email, password)
			super(email, password)
		end

		def calendars
		  @calendars ||= {}
		  if @calendars.empty?
				xs = XmlSimple.xml_in(self.get_calendars.body)
				xs['entry'].map do |cal|
			    title = cal['title'][0]['content']
			    link  = cal['link'].select{|l| l['rel']=='alternate'}.first['href'].gsub('%40','@')
			    nodes = link.split('/')
			    default_projection = nodes.pop
			    default_visibility = nodes.pop
			    link  = nodes.join('/')
			    @calendars[title] = link
				end
				@calendars[:default] = '/calendar/feeds/default'
		  end
			@calendars
		end
	
		def calendars=(value)
			@calendars = value 
		end
	
		def add_event(xml)
			post calendar_url, xml
		end

		def update_event(edit_url, xml)
			put edit_url, xml
		end

		def delete_event(edit_url)
			delete edit_url
		end

		def get_event(id)
			get "#{calendar_url}/#{id}"
		end

		def get_events(args = {})
			args.stringify_keys!
			args['start-min'] = args.delete('from') if args['from']
			args['start-max'] = args.delete('thru') if args['thru']
			args['start-max'] = args.delete('to')   if args['to']
			args['start-min'] = Time.parse(args['start-min'].to_s) if args['start-min']
			args['start-max'] = Time.parse(args['start-max'].to_s) if args['start-max']
			args['orderby'] ||= 'starttime'
			args['sortorder'] ||= 'ascending'
			raise 'invalid parameter' if args.include? 'start_time' or args.include? 'end_time'
			get "#{calendar_url}#{args.to_qs}"
		end
 
		def select_calendar(title)
			@calendar = self.calendars[title]
		end

		def get_calendars(scope = :all) # :all or :own
			get "/calendar/feeds/default/#{scope.to_s}calendars/full"
		end
	
	private
		def calendar_url
			url = []
			url << @calendar
			url << @visibility #unless (@calendar.include? 'allcalendars') or (@calendar.include? 'owncalendars')
			url << @projection
			url.join('/')
		end   
	end
   
end

