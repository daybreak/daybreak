module Dependencies
  alias old_log_call log_call
  def log_call(*args)
    begin
      relative_filename = (args[0].to_s.match('/vendor/.*')[0]).to_s.gsub('/vendor/','') rescue nil
      puts "Loading dependency: #{relative_filename}" if relative_filename && relative_filename != @@last_relative_filename
      @@last_relative_filename = relative_filename
    rescue
    ensure
      old_log_call args
    end
  end
end