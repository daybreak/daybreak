class CreateContactFacets < ActiveRecord::Migration
  def self.up
    create_table :contact_facets do |t|
      t.references :page
      t.column :contact_name, :string, :limit => 100
      t.column :contact_email, :string, :limit => 100
      t.column :contact_phone, :string, :limit => 50
      t.column :contact_full_address, :string, :limit => 300
    end
    
    add_index :contact_facets, :page_id, :unique => true
    execute "ALTER TABLE contact_facets add CONSTRAINT fk_contact_facet_page FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE;"
  end

  def self.down
    drop_table :contact_facets
  end
end

