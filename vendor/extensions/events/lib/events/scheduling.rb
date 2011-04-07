module Scheduling
	STATUSES = ["confirmed","pending", "declined", "canceled"]

  def self.included(base)
    base.facet :scheduling_facet do
    	mimic{delegate_associations; delegate 'event_id','event_id=', 'confirmed?', 'canceled?', 'pending?', 'declined?', 'starred?', 'has_setup?', 'has_teardown?', 'start_setup_at', 'end_teardown_at', 'happened?', 'days_duration', 'google_event_id', 'google_event_version', 'google_event_id=', 'google_event_version=', 'event_category_id_was', 'resource_ids', 'resource_ids=', 'continuing_events', 'image_relative_path', 'image_absolute_path', 'image_options'}
      model do
		    include FileColumnHelper
		    file_column :image, :magick => { :geometry => "900x700", :versions => { "form" => "300x300", "standard" => "400x593" } }

        belongs_to :event_category
        has_and_belongs_to_many :resources, :join_table => 'scheduling_facets_resources'

	      validates_presence_of :start_at
	      validates_presence_of :end_at
	      validates_presence_of :event_category_id

	      validates_numericality_of :setup_minutes,    :only_integer => true, :greater_than => 0, :if => Proc.new {|event| event.setup_minutes}
	      validates_numericality_of	:teardown_minutes, :only_integer => true, :greater_than => 0, :if => Proc.new {|event| event.teardown_minutes}
				validates_presence_of :expected_attendance,  :if => Proc.new {|facet| facet.page.requested?}

	      #TODO: before_update :drop_former_event ??

	      def drop_former_event
		      if self.event_category_id_changed?
		        parent = self.page
			      puts "Calendar changed on #{parent.class} #{parent.id}"
			      ge = parent.fetch_google_event(false)
            puts "-"*90
            puts ge.inspect
            puts "="*90
            ge.destroy! if ge #prevents an error when updating a canceled event
            self.google_event_id = nil
		      end
	      end

				@@filtered_event_categories = []

				def self.filtered_event_categories
					@@filtered_event_categories
				end

				def self.filtered_event_categories=(ary)
					@@filtered_event_categories = ary
				end

				#TODO: refactor how continuing events are handled.
				def continuing_events
					continuing = []
					beginning = self.start_at
					aname = self.alternate_name
					begin
						cevents = SchedulingFacet.all(:conditions => ['alternate_name = ? AND start_at > ? AND start_at <= ?', aname, beginning, beginning + 60.days], :order => 'start_at').map{|sf|sf.page}.reject{|page|page.recurrence_id}
						continuing << cevents
						beginning = cevents.last.start_at	unless cevents.length == 0
					end until cevents.length == 0
					continuing.flatten
				end

				def image_url(options = nil)
					url_for_file_column(self, "image", options)
				end

		    def confirmed?
			    self.event_status == 'confirmed'
		    end

		    def canceled?
			    self.event_status == 'canceled'
		    end

		    def pending?
			    self.event_status == 'pending'
		    end

		    def declined?
			    self.event_status == 'declined'
		    end

				def has_setup?
					!self.setup_minutes.blank? and self.setup_minutes > 0
				end

				def has_teardown?
					!self.teardown_minutes.blank? and self.teardown_minutes > 0
				end

				def start_setup_at
					self.start_at - (60 * (self.setup_minutes || 0))
				end

				def end_teardown_at
					self.end_at + (60 * (self.teardown_minutes || 0))
				end

				def happened?
					start_at < Time.now
				end

				def starred?
					self.starred
				end

				def days_duration
					(Date.parse(self.end_at.strftime('%m/%d/%Y')) - Date.parse(self.start_at.strftime('%m/%d/%Y'))).to_i
				end

				def self.find_thru(date)
					self.find_between(Date.today, date)
				end

				def self.find_since(date = Time.today)
					self.find_between(date, nil)
				end

				#used primarily for filtering "pending" requests.
				def self.find_by_status(status)
					self.all(:conditions => ["event_status = ?", status], :order => 'start_at DESC', :include => :page)
				end

				def self.find_between(from = Date.today, thru = nil)
					values = {}
					values[:f] =  from.kind_of?(String) ? Date.parse(from) : from
					values[:t] = (thru.kind_of?(String) ? Date.parse(thru) : thru).end_of_day
					values[:c] = self.filtered_event_categories unless self.filtered_event_categories.empty?
					cond = []
					cond << "start_at >= :f" if values[:f]
					cond << "start_at <= :t" if values[:t]
					cond << "event_category_id IN (:c)" if values[:c]
					conditions = [cond.join(' AND '), values] if cond.length > 0
					self.all(:conditions => conditions, :order => "start_at, id", :include => :page)
				end

				def self.has_status(status)
					self.count_status(status) > 0
				end

				def self.count_status(status)
					self.count(:conditions => ["event_status = ?", status])
				end
      end

      fields do
      	section :meta do
          add :expected_attendance
          add :alternate_name
          add :leader_name
      	end

        section :footer do
        	group :scheduling, :state => :expanded do
		        add :start_at, :input => :datetime, :classes => :stacked
		        add :end_at, :input => :datetime, :classes => :stacked
		        add :setup_minutes, :classes => :stacked
		        add :teardown_minutes, :classes => :stacked
		        add :event_category_id, :input => :dropdown, :classes => :stacked, :choices => EventCategory.all.map{|ec|[ ec.name, ec.id ]}
		        add :event_status, :input => :dropdown, :classes => :stacked, :choices => STATUSES, :label => 'Status'
		        add :location, :input => :textarea
		        add :location_url, :input => :text
		        add :image, :input => :file
		        add :starred, :input => :yes_no
          end
        end
      end
    end

  	base.class_eval do
  		validates_associated :scheduling_facet

	    def image_temp
		    scheduling_facet.try(:image_temp)
	    end

	    def image_temp=(value)
		    value = NullifyEmptyStrings.nullify(value)
		    self.build_scheduling_facet if value && !self.scheduling_facet
		    self.scheduling_facet.image_temp = value if self.scheduling_facet
	    end
	
			def adjust_date(date)
				date = Date.parse(date.to_s) unless date.kind_of? Date
				days = self.days_duration
				self.start_at = Time.parse(date.to_s + ' ' + self.start_at.strftime('%I:%M %p'))
				self.end_at   = Time.parse((date + days).to_s + ' ' + self.end_at.strftime('%I:%M %p'))
				self
			end

			#TODO: Could facets provide a feature to extend finders in this way?
			def self.find_between(from,thru)
				SchedulingFacet.find_between(from,thru).map{|s|s.page}
			end

			def self.find_thru(date)
				SchedulingFacet.find_thru(date).map{|s|s.page}
			end

			def self.find_since(date = Time.today)
				SchedulingFacet.find_since(date).map{|s|s.page}
			end

			def self.find_by_status(status)
				SchedulingFacet.find_by_status(status).map{|s|s.page}
			end
  	end

  	base.def_delegator :scheduling_facet, :image_url
  end
end

