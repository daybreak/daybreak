module Members
	module User
		def self.included(base)
			base.virtual_roles << :leader
		end

		def leader?
			self.person ? self.person.leader? : false
		end

		def reject_identity!
			self.person = nil
			self.save
		end

		def backend_access?
			self.role?
		end

		def directory_access?
			self.person.directory_access? rescue false
    end

		def registered?
			self.person.registered? rescue false
    end

		def status
			stat = :unregistered
			if self.registered?
				stat = :registered
				if self.directory_access?
					stat = :registered_with_access
				end
			end
			stat
    end
	end
end

