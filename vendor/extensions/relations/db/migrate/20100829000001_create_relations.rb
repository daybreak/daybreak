class CreateRelations < ActiveRecord::Migration
  def self.up
    create_table :relations do |t|
      t.column :superior_id, :integer, :null => false
      t.column :superior_type, :string, :null => false
      t.column :relation, :string
      t.column :subordinate_id, :integer, :null => false
      t.column :subordinate_type, :string, :null => false
      t.column :created_by_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :relations
  end
end

