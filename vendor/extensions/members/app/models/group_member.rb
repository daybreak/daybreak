class GroupMember < ActiveRecord::Base
	belongs_to :group
  belongs_to :person
  belongs_to :group_role
end
