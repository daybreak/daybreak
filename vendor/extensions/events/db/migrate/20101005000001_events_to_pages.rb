class EventsToPages < ActiveRecord::Migration
  def self.up
    execute %{
      CREATE VIEW page_events AS 
      SELECT 
        p.id, p.title, p.slug, p.breadcrumb, p.class_name, p.status_id, p.parent_id, p.layout_id, p.created_at, p.updated_at, p.published_at, p.created_by_id, p.updated_by_id, p.virtual, p.lock_version, p.position, p.appears_on, p.expires_on, p.description, p.keywords, p.role_id, p.access_key, 
        s.id as scheduling_facet_id, s.start_at, s.end_at, s.indefinite_end_time, s.event_id, s.event_category_id, s.event_status, s.location, s.location_url, s.setup_minutes, s.teardown_minutes, s.expected_attendance, s.alternate_name, s.starred, s.leader_name, s.image, s.google_event_id, s.google_event_version, 
        r.id as registration_facet_id, r.registration_start_at, r.registration_end_at, r.recurrence_id, r.capacity, r.register, r.confidential_attendance, 
        c.id as contact_facet_id, c.contact_name, c.contact_email, c.contact_phone, c.contact_full_address, 
        i.id as invitation_facet_id, i.message as invitation, i.image as invitation_image, i.color as invitation_color, 
        m.id as remark_facet_id, m.remarks as comments
      FROM pages p
      LEFT JOIN scheduling_facets   s ON s.page_id = p.id
      LEFT JOIN registration_facets r ON r.page_id = p.id
      LEFT JOIN invitation_facets   i ON i.page_id = p.id
      LEFT JOIN contact_facets      c ON c.page_id = p.id
      LEFT JOIN remark_facets       m ON m.page_id = p.id
    }

    #scheduling
    #add_column :pages, :access_key, :string, :limit => 12
    add_column :pages, :start_at, :datetime
    add_column :pages, :end_at, :datetime
    add_column :pages, :indefinite_end_time, :boolean, :default => false
    #add_column :pages, :event_id
    add_column :pages, :event_category_id, :integer
    add_column :pages, :event_status, :string, :limit => 12, :default => 'confirmed'
    add_column :pages, :location, :string, :limit => 300
    add_column :pages, :location_url, :string, :limit => 200
    add_column :pages, :setup_minutes, :integer
    add_column :pages, :teardown_minutes, :integer
    add_column :pages, :expected_attendance, :integer
    add_column :pages, :alternate_name, :string, :limit => 100
    add_column :pages, :starred, :boolean, :default => false
    add_column :pages, :leader_name, :string, :limit => 100
    add_column :pages, :image, :string, :limit => 200      
    add_column :pages, :google_event_id, :string, :limit => 100
    add_column :pages, :google_event_version, :string, :limit => 20    

    #registrations
    add_column :pages, :registration_start_at, :datetime
    add_column :pages, :registration_end_at, :datetime
    add_column :pages, :recurrence_id, :integer
    add_column :pages, :capacity, :integer
    add_column :pages, :register, :boolean, :default => false
    add_column :pages, :confidential_attendance, :boolean, :default => false
    
    #contact
    add_column :pages, :contact_name, :string, :limit => 100
    add_column :pages, :contact_email, :string, :limit => 100
    add_column :pages, :contact_phone, :string, :limit => 50
    add_column :pages, :contact_full_address, :string, :limit => 300    

    #invitation
    add_column :pages, :invitation, :text
    add_column :pages, :invitation_image, :string, :limit => 200      
    add_column :pages, :invitation_color, :string, :limit => 20

    #remarks
    add_column :pages, :comments, :string

    execute %{
      UPDATE pages p
      LEFT JOIN page_events pe ON pe.id = p.id
      SET p.start_at              = pe.start_at,
          p.end_at                = pe.end_at,
          p.indefinite_end_time   = COALESCE(pe.indefinite_end_time,0), 
          p.event_id              = pe.event_id, 
          p.event_category_id     = pe.event_category_id, 
          p.event_status          = pe.event_status, 
          p.location              = pe.location, 
          p.location_url          = pe.location_url, 
          p.setup_minutes         = pe.setup_minutes, 
          p.teardown_minutes      = pe.teardown_minutes, 
          p.expected_attendance   = pe.expected_attendance, 
          p.alternate_name        = pe.alternate_name, 
          p.starred               = pe.starred, 
          p.leader_name           = pe.leader_name, 
          p.image                 = pe.image, 
          p.google_event_id       = pe.google_event_id, 
          p.google_event_version  = pe.google_event_version, 
          p.registration_start_at = pe.registration_start_at, 
          p.registration_end_at   = pe.registration_end_at, 
          p.recurrence_id         = pe.recurrence_id, 
          p.capacity              = pe.capacity, 
          p.register              = COALESCE(pe.register,0), 
          p.confidential_attendance = COALESCE(pe.confidential_attendance,0), 
          p.contact_name          = pe.contact_name, 
          p.contact_email         = pe.contact_email, 
          p.contact_phone         = pe.contact_phone, 
          p.contact_full_address  = pe.contact_full_address, 
          p.invitation            = pe.invitation, 
          p.invitation_image      = pe.invitation_image, 
          p.invitation_color      = pe.invitation_color, 
          p.comments              = pe.comments
      WHERE p.class_name = 'Event'
    }

    add_index :pages, [:class_name, :start_at, :recurrence_id]
  
    add_column :registrations, :page_id, :integer, :null => false
    add_index  :registrations, :page_id

    execute "DELETE FROM registrations WHERE registration_facet_id IS NULL"

    execute %{
      UPDATE registrations r
      LEFT JOIN page_events p ON p.registration_facet_id = r.registration_facet_id
      SET r.page_id = p.id
    }

    execute "ALTER TABLE registrations add CONSTRAINT fk_registrations_page FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE"

    create_table :pages_resources, :id => false do |t|
      t.references :page
      t.references :resource
      t.column :created_at, :datetime
      t.column :created_by, :integer
    end
    
    execute "ALTER TABLE pages_resources ADD PRIMARY KEY (page_id, resource_id)"
    execute "ALTER TABLE pages_resources add CONSTRAINT fk_pages_resources_page FOREIGN KEY(page_id) REFERENCES pages(id) ON DELETE CASCADE"
    execute "ALTER TABLE pages_resources add CONSTRAINT fk_pages_resources_resource FOREIGN KEY(resource_id) REFERENCES resources(id) ON DELETE CASCADE"
    add_index :pages_resources, :page_id
    
    execute %{
      INSERT INTO pages_resources(page_id, resource_id, created_at, created_by)
      SELECT pe.id as page_id, s.resource_id, s.created_at, s.created_by 
      FROM scheduling_facets_resources s 
      JOIN page_events pe ON pe.scheduling_facet_id = s.scheduling_facet_id    
    }

    execute "ALTER TABLE registrations DROP FOREIGN KEY fk_registrations_registration_facet"
    remove_column :registrations, :registration_facet_id
    remove_column :registrations, :event_id

    execute "ALTER TABLE scheduling_facets DROP FOREIGN KEY fk_scheduling_facet_page"

    execute "ALTER TABLE scheduling_facets_resources DROP FOREIGN KEY fk_scheduling_facets_resources_facet"
    execute "ALTER TABLE registration_facets DROP FOREIGN KEY fk_registration_facet_page"
    execute "ALTER TABLE invitation_facets DROP FOREIGN KEY fk_invitation_facet_page"
    execute "ALTER TABLE contact_facets DROP FOREIGN KEY fk_contact_facet_page"
    execute "ALTER TABLE remark_facets DROP FOREIGN KEY fk_remark_facet_page"
                
    drop_table :scheduling_facets  
    drop_table :scheduling_facets_resources
    drop_table :registration_facets
    drop_table :invitation_facets
    drop_table :contact_facets
    drop_table :remark_facets

    drop_table :events_resources
    drop_table :events

    execute %{
      CREATE VIEW events AS 
      SELECT *
      FROM pages p
      WHERE class_name = 'Event'
    }
  end

  def self.down
  end
end

