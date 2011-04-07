module Registerable
  def self.included(base)
    #TODO: registrations needs to link to registration_facet
    base.facet :registration_facet do
    	mimic do
    		delegate 'taking_registrations?', 'registration_open?', 'describe_space', 'num_open_spots', 'has_space?', 'mailing_list', 'num_adults', 'num_children', 'num_registrants', 'confidential_attendance?'
    		delegate_associations
    	end
      model do
				belongs_to :recurrence
      	has_many :registrations, :class_name => 'Registration', :order => 'updated_at DESC, created_at DESC'

	      def num_children
		      self.registrations.inject(0){|sum, r| sum + (r.children || 0)} rescue nil
	      end

	      def num_adults
		      self.registrations.inject(0){|sum, r| sum + (r.adults || 0)} rescue nil
	      end

			  def num_registrants
				  self.registrations.inject(0){|sum, r| sum + (r.adults || 0) + (r.children || 0)} rescue nil
			  end
			  
			  def registration_open?
			    open = true
			    open = Time.now >= registration_start_at if registration_start_at && open
			    open = Time.now <= registration_end_at   if registration_end_at   && open
			    open
			  end

			  def mailing_list
				  self.registrations.map{|registrant| registrant.contact_email}.uniq
			  end

			  def has_space?
				  if num_open_spots
					  num_open_spots > 0
				  else
					  true
				  end
			  end

			  def describe_space
				  num_open_spots ? (num_open_spots == 0 ? "full" : num_open_spots.to_s + " spots left!") : "unlimited spots!"
			  end

			  def taking_registrations?
				  has_space? && self.page.confirmed?
			  end

			  # returning: nil = no limit, 0 = full, n = number of spots left
			  def num_open_spots
				  open = capacity - num_registrants if capacity
				  open = 0 if open and open < 0
				  open
			  end
      end

      fields do
        section :footer do
          group :registrations, :state => :data do
            add :registration_start_at, :input => :date, :label => 'Start at', :classes => :stacked
            add :registration_end_at  , :input => :date, :label => 'End at'  , :classes => :stacked
            add :recurrence_id, :input => :dropdown, :classes => :stacked, :include_blank => true, :choices => Recurrence.all.map{|r|[r.name, r.id]}
            add :capacity
            add :register, :input => :yes_no, :classes => :stacked, :include_blank => true
            add :confidential_attendance, :input => :yes_no, :classes => :stacked, :include_blank => true
          end
        end
      end
    end

    base.class_eval do
    	validates_associated :registration_facet
    end
  end
end

