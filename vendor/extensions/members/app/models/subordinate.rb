class Subordinate < ActiveRecord::Base
	belongs_to	:position
	belongs_to	:person
	validates_uniqueness_of :person_id, :scope => :position_id
end
