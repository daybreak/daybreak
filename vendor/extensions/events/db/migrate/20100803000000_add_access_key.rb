class AddAccessKey < ActiveRecord::Migration
  def self.up
    add_column :pages, :access_key, :string, :limit => 12
  end

  def self.down
    remove_column :pages, :access_key
  end
end

