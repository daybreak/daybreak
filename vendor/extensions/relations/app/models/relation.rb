class Relation < ActiveRecord::Base
  belongs_to :superior, :polymorphic => true
  belongs_to :subordinate, :polymorphic => true
end

