class Recurrence < ActiveRecord::Base
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
	belongs_to :recurrence_category
	has_many   :pages, :order => 'start_at, name, location'

	validates_presence_of :name
	validates_presence_of :description

	def discontinued?
		discontinued
	end

	def last_event
  	Event.find_by_sql("SELECT p.* FROM pages p WHERE p.recurrence_id = #{id} AND p.start_at < '#{DateTime.now}' ORDER BY p.start_at DESC LIMIT 1").first
	end

	def next_event
  	Event.find_by_sql("SELECT p.* FROM pages p WHERE p.recurrence_id = #{id} AND p.start_at >= '#{DateTime.now}' ORDER BY p.start_at LIMIT 1").first unless discontinued
	end

	def last_at
		last_event.start_at if last_event
	end

	def next_at
		next_event.start_at if next_event unless discontinued
	end

	def self.find_current(event = nil)
		self.all(:conditions => event && event.recurrence_id ? "id = #{event.recurrence_id}" : "discontinued = 0", :order => 'sort_order, name')
	end

	def self.find_scheduled
		self.all(:conditions => ["discontinued = 0 and exists (SELECT * FROM pages WHERE id = recurrence_id AND class_name = 'Event' AND start_at > ?)", Time.now], :order => 'sort_order, name')
	end

	def find_upcoming_events(asof = Date.today)
		Event.find_by_sql("SELECT * FROM pages WHERE recurrence_id = #{id} AND start_at >= '#{asof}'")
	end
end

=begin
class User < ActiveRecord::Base
  has_many :created_events, :class_name => 'Recurrence', :foreign_key => 'created_by'
  has_many :updated_events, :class_name => 'Recurrence', :foreign_key => 'updated_by'
end
=end

