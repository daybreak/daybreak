class Series < ActiveRecord::Base
  include FileColumnHelper

	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
	belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
	has_many :messages, :order => 'delivered_on'
	validates_presence_of :title
	validates_presence_of :description
	file_column :image, :magick => { :versions => { "standard" => "250x250" } }

	def image_url(options = nil)
    url_for_file_column(self, "image", options)
  end

	def num_messages
		messages.size
	end

	def happened?
		ended_on < DateTime.now if ended_on
	end

	def started_on
		messages.first.delivered_on if messages.size > 0
	end

	def ended_on
		messages.last.delivered_on if messages.size > 0
	end

	def self.find_empty
		self.find(:all, :conditions => ["not exists (select * from messages where series_id = series.id)"])
	end

	def chronological_status
		if Date.today > self.ended_on
			:past
		elsif Date.today < self.started_on
			:future
		else
			:current
		end
	end

	def self.next_series(message)
		Message.start_of_next_series(message).series rescue nil
	end

end

