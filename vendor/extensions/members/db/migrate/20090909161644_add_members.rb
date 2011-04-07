class AddMembers < ActiveRecord::Migration
  def self.up
    create_table "connection_states", :force => true do |t|
      t.column "state",                :string,  :limit => 25,  :default => "", :null => false
      t.column "description",          :string,  :limit => 100, :default => "", :null => false
      t.column "is_final_state",       :boolean,                                :null => false
      t.column "is_fulfillment_state", :boolean,                                :null => false
    end

    create_table "connections", :force => true do |t|
      t.column "need_id",             :integer,  :limit => 10,                :null => false
      t.column "offer_id",            :integer,  :limit => 10,                :null => false
      t.column "created_at",          :datetime,                              :null => false
      t.column "updated_at",          :datetime
      t.column "connection_state_id", :integer,  :limit => 10, :default => 0, :null => false
      t.column "followup_at",         :datetime
    end

    add_index "connections", ["need_id", "offer_id"], :name => "idx_unique_need_ofer", :unique => true
    add_index "connections", ["connection_state_id"], :name => "fk_connections_state"
    add_index "connections", ["offer_id"], :name => "fk_connections_giver"

    create_table "contact_options", :force => true do |t|
      t.column "person_id",       :integer,  :limit => 10,                 :null => false
      t.column "contact_type_id", :integer,  :limit => 10,                 :null => false
      t.column "contact_info",    :string,   :limit => 75, :default => "", :null => false
      t.column "created_at",      :datetime,                               :null => false
      t.column "updated_at",      :datetime
    end

    add_index "contact_options", ["contact_type_id"], :name => "fk_contact_options_type"
    add_index "contact_options", ["person_id"], :name => "fk_contact_options_contact"

    create_table "contact_types", :force => true do |t|
      t.column "name",       :string,   :limit => 20, :default => "", :null => false
      t.column "created_at", :datetime,                               :null => false
      t.column "code",       :string,   :limit => 3,  :default => "", :null => false
    end

    create_table "group_meetings", :force => true do |t|
      t.column "group_id",        :integer,                                 :null => false
      t.column "topic",           :string,   :limit => 70,  :default => "", :null => false
      t.column "date",            :date,                                    :null => false
      t.column "location",        :string,   :limit => 100
      t.column "guests",          :integer,                 :default => 0,  :null => false
      t.column "notes",           :text
      t.column "prayer_requests", :text
      t.column "created_at",      :datetime,                                :null => false
      t.column "updated_at",      :datetime
      t.column "created_by",      :integer,                                 :null => false
      t.column "updated_by",      :integer
    end

    add_index "group_meetings", ["group_id", "date"], :name => "idx_group_meetings_group"
    add_index "group_meetings", ["date"], :name => "idx_group_meetings_date"

    create_table "group_meetings_people", :id => false, :force => true do |t|
      t.column "group_meeting_id", :integer, :null => false
      t.column "person_id",        :integer, :null => false
    end

    create_table "group_members", :force => true do |t|
      t.column "group_id",         :integer,  :null => false
      t.column "person_id",        :integer,  :null => false
      t.column "group_role_id",    :integer
      t.column "last_attended_at", :datetime
      t.column "created_at",       :datetime, :null => false
      t.column "updated_at",       :datetime
    end

    create_table "group_roles", :force => true do |t|
      t.column "name",       :string,   :limit => 20, :default => "", :null => false
      t.column "created_at", :datetime,                               :null => false
    end

    create_table "group_types", :force => true do |t|
      t.column "name",       :string,   :limit => 20, :default => "", :null => false
      t.column "created_at", :datetime,                               :null => false
    end

    create_table "groups", :force => true do |t|
      t.column "name",                :string,   :limit => 50,  :default => "",    :null => false
      t.column "description",         :string,   :limit => 200
      t.column "meeting_place",       :string,   :limit => 100
      t.column "address",             :string,   :limit => 100
      t.column "city",                :string,   :limit => 20
      t.column "state",               :string,   :limit => 2
      t.column "zip",                 :string,   :limit => 10
      t.column "max_size",            :integer,  :limit => 2
      t.column "coach_id",            :integer
      t.column "active",              :boolean
      t.column "photo",               :string,   :limit => 100
      t.column "meeting_day",         :integer
      t.column "meeting_frequency",   :integer
      t.column "meeting_time_of_day", :time,                                       :null => false
      t.column "created_at",          :datetime,                                   :null => false
      t.column "updated_at",          :datetime
      t.column "created_by",          :integer,                                    :null => false
      t.column "updated_by",          :integer
      t.column "min_age",             :integer,  :limit => 2
      t.column "max_age",             :integer,  :limit => 2
      t.column "provides_childcare",  :boolean,                 :default => false
      t.column "group_type_id",       :integer
      t.column "study_topic",         :string,   :limit => 60
      t.column "study_starts_on",     :date
      t.column "study_ends_on",       :date
    end

    add_index "groups", ["group_type_id"], :name => "fk_groups_group_type"

    create_table "needs", :force => true do |t|
      t.column "person_id",           :integer,  :limit => 10,                :null => false
      t.column "created_at",          :datetime,                              :null => false
      t.column "updated_at",          :datetime
      t.column "occurs_at",           :datetime
      t.column "expires_at",          :datetime
      t.column "referrer_id",         :integer,  :limit => 10
      t.column "followup_at",         :datetime
      t.column "desired_connections", :integer,  :limit => 5,  :default => 1, :null => false
      t.column "origination_type_id", :integer,  :limit => 10
      t.column "service_category_id", :integer,  :limit => 10
      t.column "service_id",          :integer,  :limit => 10
    end

    add_index "needs", ["referrer_id"], :name => "fk_need_referrer"
    add_index "needs", ["origination_type_id"], :name => "fk_need_origination_type"
    add_index "needs", ["service_category_id"], :name => "fk_need_service_category_id"
    add_index "needs", ["service_id"], :name => "fk_need_service"
    add_index "needs", ["person_id"], :name => "fk_need_receiver"

    create_table "offers", :force => true do |t|
      t.column "person_id",           :integer,  :limit => 10,  :null => false
      t.column "service_id",          :integer,  :limit => 10
      t.column "withdrawn_on",        :date
      t.column "created_at",          :datetime,                :null => false
      t.column "updated_at",          :datetime
      t.column "withdrawn_reason_id", :integer,  :limit => 10
      t.column "withdrawn_comments",  :string,   :limit => 100
      t.column "service_category_id", :integer,  :limit => 10,  :null => false
    end

    add_index "offers", ["service_category_id"], :name => "fk_offer_service_category"
    add_index "offers", ["withdrawn_reason_id"], :name => "fk_offer_withdrawn_reason"
    add_index "offers", ["service_id"], :name => "fk_offer_service"
    add_index "offers", ["person_id"], :name => "fk_offer_giver"

    create_table "origination_types", :force => true do |t|
      t.column "name",       :string,   :limit => 30, :default => "", :null => false
      t.column "created_at", :datetime,                               :null => false
    end

    create_table "people", :force => true do |t|
      t.column "first_name",                :string,   :limit => 15,  :default => "",   :null => false
      t.column "last_name",                 :string,   :limit => 15,  :default => "",   :null => false
      t.column "address",                   :string,   :limit => 100
      t.column "city",                      :string,   :limit => 20
      t.column "state",                     :string,   :limit => 2
      t.column "zip",                       :string,   :limit => 10
      t.column "created_at",                :datetime,                                  :null => false
      t.column "updated_at",                :datetime
      t.column "primary_contact_option_id", :integer,  :limit => 10
      t.column "frequency",                 :integer,  :limit => 10
      t.column "frequency_unit_code",       :string,   :limit => 1
      t.column "availability_comments",     :string,   :limit => 200
      t.column "referrer_id",               :integer,  :limit => 10
      t.column "created_by",                :integer
      t.column "updated_by",                :integer
      t.column "photo",                     :string,   :limit => 200
      t.column "born_on",                   :date
      t.column "external_id",               :integer
      t.column "active",                    :boolean,                 :default => true, :null => false
      t.column "person_type_id",            :integer
      t.column "privacy_level",             :integer,                 :default => 0,    :null => false
      t.column "gender",                    :string,   :limit => 1
    end

    add_index "people", ["primary_contact_option_id"], :name => "fk_primary_contact_option"
    add_index "people", ["person_type_id"], :name => "fk_people_person_type"

    create_table "person_types", :force => true do |t|
      t.column "name",       :string,   :limit => 20, :default => "", :null => false
      t.column "created_at", :datetime,                               :null => false
    end

    create_table "position_types", :force => true do |t|
      t.column "title",      :string,   :limit => 20, :default => "", :null => false
      t.column "created_at", :datetime,                               :null => false
    end

    create_table "positions", :force => true do |t|
      t.column "person_id",        :integer,  :null => false
      t.column "created_at",       :datetime, :null => false
      t.column "position_type_id", :integer,  :null => false
    end

    create_table "subordinates", :force => true do |t|
      t.column "position_id",       :integer,  :null => false
      t.column "person_id",         :integer,  :null => false
      t.column "last_contacted_on", :date
      t.column "last_met_on",       :date
      t.column "created_at",        :datetime, :null => false
    end

    create_table "withdrawn_reasons", :force => true do |t|
      t.column "reason",     :string,   :limit => 50, :default => "", :null => false
      t.column "created_at", :datetime,                               :null => false
    end
  end

  def self.down

  end
end

