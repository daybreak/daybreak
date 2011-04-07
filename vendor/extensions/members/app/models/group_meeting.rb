class GroupMeeting < ActiveRecord::Base
	belongs_to :group
	validates_presence_of :topic, :date, :guests
	validates_numericality_of :guests
	has_and_belongs_to_many :people
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
	
	def head_count
		self.people.length + self.guests
	end
end
