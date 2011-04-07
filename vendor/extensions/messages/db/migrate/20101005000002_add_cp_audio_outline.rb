class AddCpAudioOutline < ActiveRecord::Migration
  def self.up
    add_column :messages, :cp_outline, :string, :limit => 200
    add_column :messages, :cp_audio  , :string, :limit => 200
  end

  def self.down
  end
end

