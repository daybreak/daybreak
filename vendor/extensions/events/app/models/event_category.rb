class EventCategory < ActiveRecord::Base
  has_many :pages
  belongs_to :created_by, :foreign_key => :created_by, :class_name => 'User'
  belongs_to :updated_by, :foreign_key => :undated_by, :class_name => 'User'

  def slug
  	self.name.gsub(' ', '_').downcase
  end

  def self.find_filtered_categories
    #TODO: filtered_event_categories?? how is this used? refactoring opportunity?
    if Event.filtered_event_categories.empty?
      EventCategory.find(:all, :order => 'sort_order, id')
    else
      EventCategory.find(:all, :conditions => ["id IN (?)", Event.filtered_event_categories], :order => 'sort_order, id')
    end
  end
end

