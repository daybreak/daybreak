class Registration < ActiveRecord::Base
	extend Forwardable

	belongs_to :page

	validates_presence_of  :contact_name, :adults, :children
	validates_inclusion_of :adults, :in => 0..99, :message => "must be between 0 and 99."
	validates_inclusion_of :children, :allow_nil => true, :in => 0..99, :message => "must be between 0 and 99."
	validates_uniqueness_of :contact_email, :scope => :page_id, :message => "already registered for this event.", :allow_blank => true, :allow_nil => true

	validates_each :adults, :children do |registration, attr, value|
		event = registration.page
		other = attr == :adults ? 'Children' : 'Adults'
		if event.capacity and registration.change_in_registrants > event.num_open_spots and value and value > 0
			registration.errors.add(attr, "must not (including #{other}) exceed the #{event.num_open_spots} open spots.")
		end
	end

	validates_each :contact_email, :contact_phone do |registration, attr, value|
		registration.errors.add(attr, "require at least one means of contact") unless !registration.contact_email.blank? or !registration.contact_phone.blank?
	end

	#FIXES RAILS BUG:
	before_validation { |r|
		r.contact_email = nil if r.contact_email.blank?
		r.contact_phone = nil if r.contact_phone.blank?
	}

	#TODO: helper?
	def attendee_description
		desc = []
		if adults > 1
			desc << "#{adults} adults"
		elsif adults == 1
			desc << "1 adult"
		end
		if children > 1
			desc << "#{children} children"
		elsif children == 1
			desc << "1 child"
		end
		desc.join(' and ')
	end

	def change_in_registrants
		registrants_was = 0
		if id
			r = Registration.find(id)
			registrants_was = r.registrants
		end
		registrants - registrants_was
	end

	def registrants
		total = 0
		total += adults if adults
		total += children if children
		total
	end

	def withdrawn?
		registrants < 1
	end

	def modified_at
		updated_at || created_at
	end
end

