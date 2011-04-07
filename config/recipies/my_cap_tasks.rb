Capistrano::Configuration.instance(:must_exist).load do

	namespace :deploy do

		desc "Substitute production config files in live app"
		task :reconfigure do
		  config_files.each do |file|
		    run "cp -f #{shared_path}/config/#{file} #{latest_release}/config/"
		  end
		end

	end	

	after 'deploy', 'deploy:cleanup'
	after 'deploy:update_code', 'deploy:reconfigure'
	after 'deploy:update_code', 'deploy:symlink'
	#after 'deploy:update_code', 'app:symlinks:update'

	namespace :disk do
	
		desc "Show the free disk space on host"
		task :free do
			run "df -h /"
		end
		
	end

	namespace :gems do

		desc "List all remote gems"
		task :list do
			run "gem list"
		end
		
	end

	namespace :process do
	
		desc "Show status of processes"
		task :status do
			run "top -b -n1" do |channel, stream, data|
				puts data if stream == :out
				if stream == :err
					puts "[err: #{channel[:host]}] #{data}"
					break
				end
			end
		end
		
	end

	namespace :log do
		desc "Stream log from Rails"
		task :watch, :roles => :app do
			stream "tail -f #{current_path}/log/#{rails_env}.log"
		end
	
		desc "Stream pl_analyze log"
		task :stats do
			sudo_stream "rails_stat /var/log/production.log"
		end
	
		desc "Run a script remotely"
		task :analyze, :roles => :app do
			run "cd #{current_path} && script/analyze_rails_log -f log/#{rails_env}.log" do |channel, stream, data|
				puts data
			end
		end
	end


#	desc "Run a script remotely"
#	task :log_report, :roles => :app do
#		run "cd #{current_path} && script/analyze_rails_log -f log/#{rails_env}.log" do |ch, st, data|
#		  puts data
#		end
#	end	
	
#	desc "Reconfigure app after code update"
#	task :after_update_code do
#		on_rollback {puts "***** Required config files were missing! Please copy #{config_files.join(', ')} to the server! *****"}
#		deploy.reconfigure
#		app.symlinks.update
#	end

#	desc "Configure logrotate for this app"
#	task :setup_logrotate, :roles => :app do
#		buffer = render :file => "config/recipes/logrotate.erb"
#		put buffer, "logrotate.rails"
#		sudo "mv logrotate.rails /etc/logrotate.d/rails"
#		sudo "chown root:root /etc/logrotate.d/rails"
#	end

#	namespace :commands do
#		desc "Look for commands"
#		task :look do
#			%w(ruby rake svn).each do |command|
#				run "which #{command}"
#			end
#		end
#	end

#	namespace :libs do
#		set :term, "xml"
#	
#		desc "Search /usr/lib for files named #{term}."
#		task :search do
#			run "ls -x1 /usr/lib | grep -i #{term}"
#		end

#		desc "Show the number of entries in /usr/lib."
#		task :count do
#			run "ls -x1 /usr/lib | wc -l"
#		end
#	end

end


class Capistrano::Actor

  ##
  # Run a command as root and stream it back

  def sudo_stream(command)
    sudo(command) do |channel, stream, out|
      puts out if stream == :out
      if stream == :err
        puts "[err : #{channel[:host]}] #{out}"
        break
      end
    end
  end

  # Run a task and ask for input when input_query is seen.
  # Sends the response back to the server.
  #
  # +input_query+ is a regular expression.
  #
  # Can be used where +run+ would otherwise be used.
  #
  #  run_with_input 'ssh-keygen ...'
  def run_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(:run, shell_command, input_query)
  end

  # Run a task as root and ask for input when a regular expression is seen.
  # Sends the response back to the server.
  #
  # +input_query+ is a regular expression
  def sudo_with_input(shell_command, input_query=/^Password/)
    handle_command_with_input(:sudo, shell_command, input_query)
  end

  private

  # Do the actual capturing of the input and streaming of the output.
  def handle_command_with_input(local_run_method, shell_command, input_query)
    send(local_run_method, shell_command) do |channel, stream, data|
      logger.info data, channel[:host]
      if data =~ input_query
        pass = Capistrano::CLI.password_prompt "#{data}:"
        channel.send_data "#{pass}\n"
      end
    end
  end

end
