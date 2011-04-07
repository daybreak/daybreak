class Admin::TasksController < ApplicationController
  no_login_required
  def collect_garbage
    puts 'Garbage Collection Request'
    GC.start
    render :text => 'Garbage Collection Request'
  end	

	def monitor_memory
		render :text => `free -m`
	end

	def free_megabytes
		render :text => get_memory.to_s
	end

private
	
	def get_memory
		freed = `free -m`
		line = freed.split("\n")[1]
		line = line.gsub('  ',' ') while line.index('  ')
		line.split(' ')[3].to_i
	end	
	  
end
