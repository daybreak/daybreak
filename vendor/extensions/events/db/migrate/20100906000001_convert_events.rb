require 'pp'

class ConvertEvents < ActiveRecord::Migration
  def self.up
    raise 'Must disconnect from Google first!' if Event.included_modules.include? Googlize
    legacy_events = LegacyEvent.all
    converted, failed = Event.process(legacy_events)
    failed.each do |f|
      puts '## FAILURE ##'
      pp f.errors.full_messages
      pp f
    end    
    failed.empty? || raise("Unable to migrate legacy events.")
    puts "Total    : #{legacy_events.length}"    
    puts "Converted: #{converted.length}"
    puts "Failed   : #{failed.length}"
  end

  def self.down
    raise 'Cannot migrate down!'
  end
end

