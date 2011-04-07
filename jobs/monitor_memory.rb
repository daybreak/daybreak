#!/usr/bin/ruby
def get_memory
  freed = `free -m`
  line = freed.split("\n")[1]
  line = line.gsub('  ',' ') while line.index('  ')
  line.split(' ')[3].to_i
end

memory = get_memory
puts "#{Time.now} - Memory: #{memory}M"
if memory < 15
  puts `/etc/init.d/mongrel_cluster restart`
  memory = get_memory
  puts "#{Time.now} - Memory: #{memory}M *"
end
