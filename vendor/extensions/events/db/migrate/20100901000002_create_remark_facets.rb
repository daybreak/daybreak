class CreateRemarkFacets < ActiveRecord::Migration
  def self.up
    create_table :remark_facets do |t|
      t.references :page
      t.string :remarks
    end
    
    add_index :remark_facets, :page_id, :unique => true
    execute "ALTER TABLE remark_facets add CONSTRAINT fk_remark_facet_page FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE;"
  end

  def self.down
    drop_table :remark_facets
  end
end

