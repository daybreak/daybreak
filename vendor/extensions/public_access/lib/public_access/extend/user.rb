module PublicAccess
	module User
		module ClassMethods
      #virtual roles are dynamically derived and not assigned; however, the User model must be told about them.
			def virtual_roles
				@@virtual ||= Set.new()
			end

			def entered_roles
				Role.all.map{|role| role.role_name.downcase.to_sym }
			end

			def roles
				Set.new(self.entered_roles.to_a + self.virtual_roles.to_a)
			end
		end

		def role?(which = nil)
			which = which.name.underscore if which.is_a?(Role)
			which ? self.send("#{which}?") : self.roles.map{|role| role.name.underscore }.any?{|role| self.send "#{role}?"}
		end

		#TODO: after Radiant upgrade, rename "developer" => "designer"
		#TODO: replace with published landing_page extension?
		def landing_page
			if self.writer? or self.designer? or self.admin? or self.staff?
				"/admin/pages"
     	elsif self.leader?
      	"/admin/group"
      elsif self.directory_access?
      	"/directory"
      else
				"/"
      end
		end

    def person?
      self.person != nil
    end
    
    def developer?
      designer?
    end

    def directory_access?
    	person? && person.directory_access?
    end

		def first_name
			self.name.split(" ").first
		end

		def last_name
			self.name.split(" ").last
		end

		def lock!
			self.locking_key = Page.generate_key #TODO: extract generate_key to its own area
			save
		end

		def unlock!
			self.locking_key = nil
			save
		end

		def unlocked?
			self.locking_key.blank?
		end

		def locked?
			!self.locking_key.blank?
		end

		def find_person
			person = nil
			options = ContactOption.find(:all, :conditions => ["contact_info = ?", self.email])
			if options
				people = []
				options.collect{ |o| o.person }.uniq.each{ |p| people << p }
				people.reject!{ |p| p.user }

				names = self.name.split(" ")
				first_name = names.first
				last_name = names.last

				most_similarity = 0
				people.each do |p|
					similarity  = 1
					similarity += 1 if p.first_name.include?(first_name)
					similarity += 1 if p.last_name.include?(last_name)
					similarity += 1 if p.full_name == self.name
					if similarity > most_similarity
						person = p
						most_similarity = similarity
					end
				end
			end
			person
		end

		def attach_person!
			unless self.person or self.locked? #do not attach if already attached or locked
				self.person = self.find_person
				self.save!
        self.person
      else
        nil
			end
		end
	end
end

