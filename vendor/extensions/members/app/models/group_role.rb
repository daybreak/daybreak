class GroupRole < ActiveRecord::Base
    has_one :group_member
    validates_presence_of :name
    
    def leader?
    	self.id == 1
    end
end
