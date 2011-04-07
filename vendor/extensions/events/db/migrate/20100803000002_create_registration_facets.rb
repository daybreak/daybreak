class CreateRegistrationFacets < ActiveRecord::Migration
  def self.up
    create_table :registration_facets do |t|
      t.references :page
      t.column :registration_start_at, :datetime
      t.column :registration_end_at, :datetime
      t.references :recurrence
      t.column :capacity, :integer
      t.column :register, :boolean, :null => false
      t.column :confidential_attendance, :boolean, :null => false
    end

    add_index :registration_facets, :page_id, :unique => true
    add_index :registration_facets, :recurrence_id
    add_column :registrations, :registration_facet_id, :integer
    
    execute "ALTER TABLE registration_facets add CONSTRAINT fk_registration_facet_page FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE;"
    execute "ALTER TABLE registrations add CONSTRAINT fk_registrations_registration_facet FOREIGN KEY (registration_facet_id) REFERENCES registration_facets(id) ON DELETE CASCADE;"       
  end

  def self.down
    drop_table :registration_facets
    drop_column :registrations, :registration_facet_id
  end
end

