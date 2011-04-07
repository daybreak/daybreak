class CreateInvitationFacets < ActiveRecord::Migration
  def self.up
    create_table :invitation_facets do |t|
      t.references :page
      t.column :message, :text  , :null => false
      t.column :image  , :string, :limit => 200      
      t.column :color  , :string, :limit => 20
    end
    
    add_index :invitation_facets, :page_id, :unique => true
    execute "ALTER TABLE invitation_facets add CONSTRAINT fk_invitation_facet_page FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE;"
  end

  def self.down
    drop_table :invitation_facets
  end
end

