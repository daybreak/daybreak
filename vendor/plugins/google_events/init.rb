require 'net/http'
require 'net/https'
require 'uri'
require 'rexml/document'
require 'xmlsimple'
require 'client'
require 'event'
require 'calendar'
#require 'pp'

module XmlParser
	def to_xs(xml)
		if xml.respond_to? :body #is this an html response?
			response = xml
			xml = response.body   
		end
		XmlSimple.xml_in(xml)
	end
end

class Net::HTTPS < Net::HTTP
  def initialize(address, port = nil)
    super(address, port)
    self.use_ssl = true
  end
end

class Hash
	def to_qs(prefix = '?', separator = '&')
		qs = []
		self.each_pair do |key, value| 
			value = value.iso8601 if value.respond_to? :iso8601
			qs << key.to_s + '=' + value.to_s
		end
		(qs.empty? ? '' : prefix) + qs.join(separator)
	end
	
	def stringify_keys!
		keys.each do |key|
		  self[key.to_s] = delete(key)
		end
		self
	end	
end

module Google::HTTPLogger
  def self.log(action, url, response, data = nil)
      puts "#{action.to_s} #{url} -> #{response.code} #{response.code_type}"
      puts data if data
  end
end

module Google #console method for viewing events
	def view(events) #handles google events or local events
		puts 'Remote Events' if event.respond_to? :start_time
		puts 'Local Events'  if event.respond_to? :start_at
		events.each do |event|
			puts event.title.ljust(35) + " " + event.start_time.to_s if event.respond_to? :start_time
			puts event.title.ljust(35)  + " " + event.start_at.to_s  if event.respond_to? :start_at
		end
		nil
	end
end


