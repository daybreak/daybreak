class ContactType < ActiveRecord::Base
    has_one :contact_option
    validates_presence_of :name
end
