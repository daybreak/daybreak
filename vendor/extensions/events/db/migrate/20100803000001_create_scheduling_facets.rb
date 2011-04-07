class CreateSchedulingFacets < ActiveRecord::Migration
  def self.up
    add_column :pages, :event_id, :integer 
  
    create_table :scheduling_facets do |t|
      t.references :page
      t.column :start_at, :datetime, :null => false
      t.column :end_at, :datetime, :null => false
      t.column :indefinite_end_time, :boolean, :default => false
      t.references :event #TODO: temporary, for conversion purposes
      t.references :event_category, :null => false
      t.column :event_status, :string, :limit => 12, :null => false, :default => 'confirmed'
      t.column :location, :string, :limit => 300
      t.column :location_url, :string, :limit => 200
      t.column :setup_minutes, :integer
      t.column :teardown_minutes, :integer
      t.column :expected_attendance, :integer
      t.column :alternate_name, :string, :limit => 100
      t.column :starred, :boolean, :default => false
      t.column :leader_name, :string, :limit => 100
      t.column :image, :string, :limit => 200      
      t.column :google_event_id, :string, :limit => 100
      t.column :google_event_version, :string, :limit => 20
    end

    #http://errtheblog.com/posts/14-composite-migrations
    create_table :scheduling_facets_resources, :id => false do |t|
      t.references :scheduling_facet
      t.references :resource
      t.column :created_at, :datetime
      t.column :created_by, :integer
    end

    add_index :scheduling_facets, :class_name
    add_index :scheduling_facets, :page_id, :unique => true
    add_index :scheduling_facets_resources, [:scheduling_facet_id, :resource_id], :unique => true
    
    execute "ALTER TABLE scheduling_facets add CONSTRAINT fk_scheduling_facet_page FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE;"
    execute "ALTER TABLE scheduling_facets_resources add CONSTRAINT fk_scheduling_facets_resources_facet FOREIGN KEY(scheduling_facet_id) REFERENCES scheduling_facets(id) ON DELETE CASCADE;"
  end

  def self.down
    drop_table :scheduling_facets_resources
    drop_table :scheduling_facets
    remove_column :pages, :event_id
  end
end

