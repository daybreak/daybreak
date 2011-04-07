class Resource < ActiveRecord::Base
  has_and_belongs_to_many :pages
  belongs_to :resource_category
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'

  def category
    self.resource_category.name
  end
end

