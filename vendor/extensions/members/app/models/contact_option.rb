class ContactOption < ActiveRecord::Base
  belongs_to 	:person
  belongs_to	:contact_type
  validates_presence_of :contact_info, :contact_type_id, :person_id
    
  def self.for_person(person)
    option = self.new
    option.person = person
    option
  end
end
