class Position < ActiveRecord::Base
  belongs_to 	:person
  has_many    :subordinates, :dependent => :destroy
  belongs_to	:position_type  
  validates_presence_of :position_type_id, :person_id
  validates_uniqueness_of :position_type_id, :scope => :person_id
    
  def self.for_person(person)
    position = self.new
    position.person = person
    position
  end
  
  def title
  	position_type.title
  end
  
  def people
  	subordinates.collect{|subordinate| subordinate.person }
  end
  
	def add_subordinate(person)
		Subordinate.new(:person_id => person.id, :position_id => id).save
	end

	def remove_subordinate(person)
		Subordinate.find(:first, :conditions => ['person_id = ? and position_id = ?', person.id, id]).destroy
	end
end
