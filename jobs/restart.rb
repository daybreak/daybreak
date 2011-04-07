#!/usr/bin/ruby
puts "#{Time.now} - Bouncing..."
puts `/etc/init.d/mongrel_cluster restart`
puts "Bounced."
