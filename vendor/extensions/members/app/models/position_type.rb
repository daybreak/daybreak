class PositionType < ActiveRecord::Base
    has_many :positions
    validates_presence_of :title
end

