class PersonType < ActiveRecord::Base
    validates_presence_of :name
    has_one :person
end
