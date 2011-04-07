#!/usr/bin/ruby
# conv_people.rb

require 'rubygems'
require 'pp'
require "active_support"
require "active_record"

args = {}

TEMPLATE = "conv_people -db <database> -p <password> [-l <limit>] [-mdb <mdb_file>] [-d] [-f]\n\t-f = force\n\t-d = detailed"

ARGV.each_index do |i|
	args[:detailed] = true if ARGV[i] == '-d'
	args[:limit] = ARGV[i + 1].to_i if ARGV[i] == '-l'
	args[:database] = ARGV[i + 1] if ARGV[i] == '-db'
	args[:mdb] = ARGV[i + 1] if ARGV[i] == '-mdb'
	args[:password] = ARGV[i + 1] if ARGV[i] == '-p'
	args[:force] = true if ARGV[i] == '-f'
end

#apply defaults:
args[:mdb] ||= './connectdata.mdb'
args[:force] ||= false

if args[:database].to_s.length == 0 or args[:password].to_s.length == 0
	puts TEMPLATE
	exit
end

DELIMITER = '::'

# establish the connection to the local database
ActiveRecord::Base.establish_connection({
      :adapter  => "mysql", 
      :database => args[:database],
      :host     => "localhost",
      :username => "rails",
      :password => args[:password] 
})

# identify the models with which we are working in the target database
class Person < ActiveRecord::Base
  has_many   :contact_options, :order => "created_at", :dependent => :destroy
  self.record_timestamps = false
end

class ContactOption < ActiveRecord::Base
  belongs_to 	:person
end

#execute mdb sql
def mdb_sql(mdb_file, sql)
  # libMDB barks on stderr quite frequently, so discard stderr entirely
	command = "mdb-sql -Fp -d '#{DELIMITER}' #{mdb_file} 2> /dev/null \n"
  lines = nil
  fields = nil
  IO.popen(command, 'r+') do |pipe|
    pipe << "#{sql}\ngo\n"
    pipe.close_write
    pipe.readline
    fields = pipe.readline.chomp.split(DELIMITER)
    lines = pipe.readlines
  end
  new_lines = []
  new_line = ''
  lines.each do |line|
  	if (line + new_line).split(DELIMITER).length > fields.length
    	new_lines << new_line.chomp
  	  new_line = ''
  	end
  	new_line += line
  end
  new_lines << new_line.chomp
  rows = []
  new_lines.each do |line|
    row = {}
    values = line.split(DELIMITER)
  	values.each_index do |i|
  		row[fields[i]] = values[i]
  	end
  	rows << row
  end
  rows
end

def ctime(str)
	return nil if str.blank?
	dt = Time.parse(str.to_s)
	return dt.to_s
	tm = dt.strftime('%r') rescue nil
	yr = dt.year if dt
	yr = expand_year(yr)
	out = Time.parse("#{dt.month}/#{dt.day}/#{yr} #{tm}") rescue nil
	out.strftime('%F %r') rescue nil
end

def expand_year(yr)
	yr = yr.to_i
	yr = (yr >  Date.today.strftime('%y').to_i ? '19' : '20') + yr.to_s if yr.to_s.length == 2
	yr
end

def cdate(str)
	return nil if str.blank?
	str = str.split(' ').first
	mm, dd, yr = str.split('/')
	yr = expand_year(yr)
	Date.parse("#{mm}/#{dd}/#{yr}") rescue nil 
end

def convert_people(contacts, limit = nil)
	# load converted people into a hash table
	people = {}
	failed = []
	dirty = []
	reads = 0
	contacts.each do |contact|
		reads += 1
		external_id = contact['ContactID'].to_i
		break if limit and reads > limit
		#puts "#{reads}. #{contact['FirstName']} #{contact['LastName']}"
		begin
			address_lines = contact['MailingAddress'].split("\r\n")
			address = []
			while address_lines.length > 1
				address << address_lines.shift
			end
			city_state_zip = address_lines.shift
			raise "Bad address" if address == nil or city_state_zip == nil or city_state_zip.length < 10
			address = address.join("\r\n")
			city, state_zip = city_state_zip.split(",")
			state, zip = state_zip.strip.split(" ")
		rescue => error
			address = nil
			city = nil
			state = nil
			zip = nil
		end
		begin
			person_type_id, active, deceased = conv_status(contact['Status'])
			raise "Deceased person skipped" if deceased 
			raise "Person type missing" if person_type_id == nil
			raise "Missing first or last name" if contact['FirstName'].length == 0 || contact['LastName'].length == 0
			person = {
				:external_id		=> external_id,
				:first_name 	  => "#{contact['FirstName']} #{contact['MiddleName']}".strip,
				:last_name		  => contact['LastName'],
				:address			  => address,
				:city					  => city,
				:state				  => state,
				:zip					  => zip,
				:born_on 			  => cdate(contact['Birthdate']),
				:gender				  => (contact['Gender'].to_s == '1' ? 'M' : 'F'),
				:person_type_id	=> person_type_id,
				:active				  => active,
				:privacy_level  => 2,
				:updated_at     => ctime(contact['DateUpdated']),
				:created_at     => ctime(contact['DateCreated']),
				:contact_options=> []
				}
			people[external_id] = person
		rescue => error
			failed << [contact, error]
		end
	end
	[people, failed, dirty]
end

def convert_phones(phone_numbers, people)
	reads = 0
	failed = []
	phone_numbers.each do |phone_number|
		reads += 1
		#locate the person (converted above)
		internal_id = phone_number['ContactID'].to_i
		person = people[internal_id]
		begin
			if person
				contact_type_id = conv_phone_type(phone_number['PhoneType']) if phone_number['Private'].to_i == 0
				if contact_type_id
					#puts "#{reads}. #{phone_number['Phone']} (#{phone_number['PhoneType']}) for #{person[:first_name]} #{person[:last_name]}"
					contact_option = {
						:contact_info    => phone_number['Phone'],
						:contact_type_id => contact_type_id,
						:updated_at      => ctime(phone_number['DateUpdated']),
						:created_at      => ctime(phone_number['DateCreated'])
					}
					person[:contact_options] ||= []
					person[:contact_options] << contact_option
				end
			else
				raise "Orphan phone number"
			end
		rescue => error
			failed << [phone_number, error]
		end
	end
	[failed, []]
end

# conversion helper methods
def conv_status(old_status)
	active = 1
	deceased = false
	case old_status.to_i
		when 10, 20, 30, 40, 41, 107
			person_type_id = 2
		when 50, 51, 52, 53
			person_type_id = 2
			active = 0
		when 99
			person_type_id = 2
			active = 0
			deceased = true
		when 60
			person_type_id = 1
		when 5
			person_type_id = 3
		when 100
			person_type_id = 3
			active = 0
			deceased = true
		when 101, 102, 103, 104, 105
			person_type_id = 3
			active = 0
		when 0, 1, 2, 3
			person_type_id = 4
		when 4
			person_type_id = 4
			active = 0
		when 108, 109, 110, 111, 112, 90
			person_type_id = nil			
		else
			raise "Status not mapped from #{old_status}."
		end
		[person_type_id, active, deceased]
end

def conv_phone_type(old_phone_type)
	case old_phone_type.to_i
		when 3, 15
			contact_type_id = 1
		when 1, 12
			contact_type_id = 2
		when 2, 13
			contact_type_id = 3
		when 5
			contact_type_id = 4
		else
			contact_type_id = nil
	end
	contact_type_id
end

def identify_person(person)
	(person[:external_id].to_s + ' ' + [person['first_name'], person['last_name']].join(' ')).to_s
end

def show_person(person, new_record)
	puts ''
	puts "[#{identify_person(person)} #{new_record ? ' (new)' : ''}]"
	puts '=PERSON='
	puts person.attributes.to_yaml.to_s[5..-1]
	person.contact_options.each do |co|
		puts ''
		puts '=CONTACT OPTION='
		puts co.attributes.to_yaml.to_s[5..-1]
	end
end

def import(people, detailed = false, force = false)
	inserted_people = []
	updated_people = []
	inserted_contact_options = []
	updated_contact_options = []
	while import_person = people.shift
		key, attributes = import_person
		import_contact_options = attributes.delete(:contact_options)
		person = Person.find_by_external_id(key) || Person.new
		web_updated_at = person.new_record? ? nil : Time.parse(person[:updated_at].to_s)
		master_updated_at = Time.parse(attributes[:updated_at].to_s)
		person.attributes = attributes
		
		if person.new_record?
			status = 'master   '
		elsif web_updated_at == master_updated_at
			status = 'unchanged'
		elsif web_updated_at > master_updated_at
			status = 'web      '
		else
			status = 'master   '			
		end
		
		new_person = person.new_record?
		
		if new_person
			action = 'I'
		elsif status == 'unchanged' and !force
			action = 'S'
		else
			action = 'U'
		end

		unless action == 'S'
			person.save
			person.update_attribute(:updated_at, Time.parse(attributes[:updated_at].to_s))
			person.update_attribute(:created_at, Time.parse(attributes[:created_at].to_s))
		end
		
		puts "#{action} #{identify_person(person).ljust(34)} -> status: #{status}, w:#{(web_updated_at.strftime('%m/%d/%Y %I:%M:%S %p') rescue '').ljust(22)}, m:#{master_updated_at.strftime('%m/%d/%Y %I:%M:%S %p')}"	unless status == 'unchanged'
		show_person(person, new_person) if detailed
		inserted_people << person if new_person
		updated_people << person unless new_person

		contact_options = ContactOption.find(:all, :conditions => ["person_id = ?", person.id])	
		import_contact_options.each do |import_contact_option|	
			same = contact_options.select{|contact_option| contact_option.contact_type_id == import_contact_option[:contact_type_id] and contact_option.contact_info == import_contact_option[:contact_info]}
			next if same.any?
			same_type = contact_options.select{|contact_option| contact_option.contact_type_id == import_contact_option[:contact_type_id]}
			if same_type.any?
				contact_option = same_type.first 
				contact_option.attributes = import_contact_option
				contact_option.save
				updated_contact_options << contact_option
			else
				contact_option = ContactOption.new(import_contact_option)
				contact_option.person_id = person.id
				contact_option.save
				inserted_contact_options << contact_option
			end
		end
	end
	[inserted_people, updated_people, inserted_contact_options, updated_contact_options]
end

# Orchestrate Conversion

people, failed_people, dirty_people = [], [], []
failed_contact_info, dirty_contact_info = [], [], []
inserted_people, updated_people, inserted_contact_options, updated_contact_options = [], [], [], []

begin
	puts ''
	puts 'Start: ' + Time.now.to_s
	contacts = mdb_sql(args[:mdb], "select ContactID, FirstName, MiddleName, LastName, Birthdate, Gender, Status, MailingAddress, DateUpdated, DateCreated from tblContacts")
	phone_numbers = mdb_sql(args[:mdb], "select ContactID, Phone, PhoneType, Private, DateUpdated, DateCreated from tblPhoneNumbers")

	people, failed_people, dirty_people = convert_people(contacts, args[:limit])
	failed_contact_info, dirty_contact_info = convert_phones(phone_numbers, people)
	#people = people.select{|external_id, person| person[:last_name] == 'Argot'}
	#pp people
	inserted_people, updated_people, inserted_contact_options, updated_contact_options = import(people, args[:detailed], args[:force])
	`mv #{args[:mdb]} /var/www/daybreak/public/import/imported/#{args[:mdb].to_s.split('/').last}`
rescue => e
	puts e.to_s
	
ensure

	puts ''
	puts "Stop: " +  Time.now.to_s
	puts "People: #{inserted_people.length} inserted, #{updated_people.length} updated, #{failed_people.length} failed, #{dirty_people.length} dirty"
	puts "Contact Options: #{inserted_contact_options.length} inserted, #{updated_contact_options.length} updated, #{failed_contact_info.length} failed, #{dirty_contact_info.length} dirty "

	dirty_people.each{|line| STDERR.puts PP.pp(line, String.new)}
	failed_people.each{|line| STDERR.puts PP.pp(line, String.new)}
	dirty_contact_info.each{|line| STDERR.puts PP.pp(line, String.new)}
	failed_contact_info.each{|line| STDERR.puts PP.pp(line, String.new)}
end

