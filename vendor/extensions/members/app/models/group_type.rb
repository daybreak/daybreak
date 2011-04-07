class GroupType < ActiveRecord::Base
    has_one :group
    validates_presence_of :name
end
