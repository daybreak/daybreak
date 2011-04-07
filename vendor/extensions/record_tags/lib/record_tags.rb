module RecordTags
	include Radiant::Taggable

	class TagError < StandardError; end

#TODO: don't allow displaying of password values.
#TODO: custom formatting of dates, currency, etc.

	tag 'record' do |tag|
		raise TagError, "'#{tag.name}' tag must contain a 'model' attribute." unless tag.attr['model']		
		raise TagError, "'#{tag.name}' tag must contain a 'conditions' or an 'id' attribute." unless tag.attr['conditions'] or tag.attr['id']
		record = eval("#{tag.attr['model']}.find(:first, :conditions => tag.attr['conditions'], :order => tag.attr['order'])") if tag.attr['conditions']
		record = eval("#{tag.attr['model']}.find(#{tag.attr['id']})") if tag.attr['id']
		tag.locals.record = record
		tag.expand if record
	end

	tag 'record:if_value' do |tag|
		if_value(tag)
	end

	tag 'record:unless_value' do |tag|
		unless_value(tag)
	end

	tag 'record:value' do |tag|
		get_value(tag)
	end

	tag 'record:range' do |tag|
		get_range(tag)
	end

	tag 'records' do |tag|
		raise TagError, "'#{tag.name}' tag must contain a 'model' attribute." unless tag.attr['model']
		if tag.attr['id']
			records = eval("#{tag.attr['model']}.find(tag.attr['id'])")
		else
			records = eval("#{tag.attr['model']}.find(:all, :conditions => tag.attr['conditions'], :order => tag.attr['order'], :offset => tag.attr['offset'], :limit => tag.attr['limit'])")
		end
		tag.locals.model = tag.attr['model']
		tag.locals.records = records
		tag.expand
	end

	tag 'records:if_returned' do |tag|
		tag.expand if has_records(tag)
	end

	tag 'records:unless_returned' do |tag|
		tag.expand unless has_records(tag)
	end

	tag 'records:count' do |tag|
		has_records(tag) ? tag.locals.records.length : 0
	end

	tag 'records:if_returned:each' do |tag|
		expand_records(tag)
	end

	tag 'records:if_returned:each:file' do |tag|
		file_name = get_value(tag, :double)
		tag.locals.file_name = file_name if file_name
		file_name and File.exists?(file_name) and !File.zero?(file_name) ? tag.expand : ''
	end

	tag 'records:if_returned:each:file:path' do |tag|
		File.expand_path(tag.locals.file_name)
	end

	tag 'records:if_returned:each:file:url' do |tag|
		file_url(File.expand_path(tag.locals.file_name))
	end

	tag 'records:if_returned:each:file:type' do |tag|
		require 'mime/types'
		MIME::Types.type_for(tag.locals.file_name).to_s
	end

	tag 'records:if_returned:each:file:size' do |tag|
		File.size?(tag.locals.file_name)
	end

	tag 'records:if_returned:each:file:basename' do |tag|
		File.basename(tag.locals.file_name)
	end	
	
	tag 'records:if_returned:each:if_value' do |tag|
		if_value(tag)
	end

	tag 'records:if_returned:each:unless_value' do |tag|
		unless_value(tag)
	end

	tag 'records:if_returned:each:parent' do |tag| 
		tag.expand if get_parent(tag)
	end

	tag 'records:if_returned:each:if_parent' do |tag|
		tag.expand if get_parent(tag)
	end

	tag 'records:if_returned:each:unless_parent' do |tag| 
		tag.expand unless get_parent(tag)
	end

	tag 'records:if_returned:each:parent:value' do |tag| 
		get_value(tag)
	end

	tag 'records:if_returned:each:parent:children' do |tag| 
		tag.expand if get_children(tag)
	end

	tag 'records:if_returned:each:parent:if_children' do |tag| 
		tag.expand if get_children(tag)
	end

	tag 'records:if_returned:each:parent:children:each' do |tag| 
		expand_records(tag)
	end

	tag 'records:if_returned:each:parent:if_children:each' do |tag| 
		expand_records(tag)
	end

	tag 'records:if_returned:each:parent:unless_children' do |tag| 
		tag.expand unless get_children(tag)
	end

	tag 'records:if_returned:each:value' do |tag|
		get_value(tag)
	end

	tag 'records:if_returned:each:range' do |tag|
		get_range(tag)
	end

	tag 'records:if_returned:each:image' do |tag|
		value = get_value(tag)
		tag.attr.delete('for')
		return unless value
		nodes = value.split('/')
		version = tag.attr.delete('version')
		found_public = false
		path = ''
		nodes.each do |node|
			path += '/' + version if version && node == nodes.last 
			path += '/' + node if found_public 
			found_public = true if node == 'public'
		end
		options = ''
		tag.attr.each {|k,v| options += " #{k}='#{v}'"}
		"<img src='#{path}'#{options}/>"
	end

private

	def handles_comparison(tag)
		#return true if tag.attr.has_key?('eval')
		items = comparisons.to_a.collect{|item| item if tag.attr.has_key?(item[0])}
		items.size > 0 ? items : nil 
	end
	
	def comparisons
		{"lt" => "<", "lte" => "<=", "eq" => "==", "gte" => ">=", "gt" => ">"}
	end
	
	def eval_comparison(tag)
		field = eval("tag.locals.record.#{tag.attr['for']}")
		items = handles_comparison(tag)
		if items
			expressions = items.collect do |item| 
				tag_name, comp = item
				value = tag.attr[tag_name]
				"field #{comp} #{value}"
			end
			eval(expressions.join(' and '))
		else
			return nil
		end
	end
	
	def has_value(tag)
		raise TagError, "'#{tag.name}' tag must contain a 'for' attribute." unless tag.attr['for']
		field = eval("tag.locals.record.#{tag.attr['for']}")
		tag.locals.field = field
		!field.blank?
	end

	def if_value(tag)
		if handles_comparison(tag)
			if eval_comparison(tag)
				tag.expand
			end
		else
			if has_value(tag)
				tag.expand
			end
		end
	end

	def unless_value(tag)
		if handles_comparison(tag)
			unless eval_comparison(tag)
				tag.expand
			end
		else
			unless has_value(tag)
				tag.expand
			end
		end
	end

	def has_records(tag)
		records = tag.locals.records
		records && records.length > 0
	end

	def expand_records(tag)
		result = []
		records = tag.locals.records
		records.each do |record|
			tag.locals.record = record
			result << tag.expand
		end
		result
	end

	def get_parent(tag)
		tag.locals.record = eval("tag.locals.record.#{tag.attr['model'].downcase}")
	end

	def get_children(tag)
		tag.locals.records = eval("tag.locals.record.#{tag.attr['model'].downcase}")
	end
	
	def get_range(tag)
		format_range(eval("tag.locals.record.#{tag.attr['from']}"), eval("tag.locals.record.#{tag.attr['thru']}"), :use_date => tag.attr['use_date'], :prefix => tag.attr['prefix'], :date_format => tag.attr['date_format'], :time_format => tag.attr['time_format'] )
	end
	
	def get_value(tag, tag_type = :single)
		raise TagError, "'#{tag.name}' tag must be empty." if tag.double? and tag_type == :single
		tag.locals.field ||= eval("tag.locals.record.#{tag.attr['for']}")
		format = tag.attr['format']
		field = tag.locals.field
		case field.class.to_s
			when "Time", "Date", "DateTime"
				format ||= '%m/%d/%Y' #'%A, %B %d, %Y'
				field.strftime(format)
			else
				field
		end
	end
	
end

def to_boolean(value)
	case value
		when nil, 'false', :false, false, 'no', :no, 0, '0'
			false
		when 'true', :true, true, 'yes', :yes, 1, '1'
			true
		else #per Ruby, if we have a value, we're true
			true
		end
end

def is_midnight?(date)
	date.strftime('%l:%M %p') == '12:00 AM'
end

def format_range(from, thru, options = {})
		date_format = options[:date_format] || '%m/%d/%Y' rescue '%m/%d/%Y'
		time_format = options[:time_format] || '%l:%M %p' rescue '%l:%M %p'
		prefix    = from == thru ? nil : options[:prefix]
		suffix    = options[:suffix]
		use_date  = to_boolean(options[:use_date])
		from_date = from.strftime(date_format) 
		from_time = is_midnight?(from)     ? nil : from.strftime(time_format) 
		thru_date = from_date == thru_date ? nil : thru.strftime(date_format)
		thru_time = is_midnight?(thru)     ? nil : thru.strftime(time_format)
		
		range = []
		range << from_date if use_date
		range << from_time if from_time
		range << '-' if (thru_date and use_date) or thru_time
		range << thru_date if thru_date and use_date
		range << thru_time if thru_time
		if range.length > 0 
			range.insert(0, prefix) if prefix
			range << suffix if suffix
		end
		range.join(' ')	
end

def file_url(path)
  path = File.expand_path(path)
  url = ''
  found_public = false
  path.split('/').each do |part|
    url += '/' + part if found_public
    found_public = true if part == 'public'
  end 
  url
end
