class SetupLegacyRoles < ActiveRecord::Migration

  def self.up
    User.send :has_and_belongs_to_many, :roles
    self.setup_writers
    self.setup_staff
    remove_column :users, :writer
    remove_column :users, :staff
    Role.create!(:role_name => 'Leader') #former derived role won't be derived henceforth
  end
  def self.down
    say("Removing all Roles.")
    Role.find(:all, :conditions => ["role_name IN ('Writer','Staff','Leader')"]).map(&:destroy)
  end

  def self.setup_writers
    writers = User.find_all_by_writer(true)
    role = Role.create!(:role_name => 'Writer')
    writers.each do |user|
      say("Adding #{user.login} to the #{role.role_name} role.")
      user.roles << role
    end
  end

  def self.setup_staff
    staff = User.find_all_by_staff(true)
    role = Role.create!(:role_name => 'Staff')
    staff.each do |user|
      say("Adding #{user.name} to the #{role.role_name} role.")
      user.roles << role
    end
  end

end

