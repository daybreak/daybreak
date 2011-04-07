# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
require File.join(File.dirname(__FILE__), 'boot')

require 'radius'
require 'rss/2.0'
require 'rss/itunes'

Radiant::Initializer.run do |config|
  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  config.frameworks -= [ :action_mailer ]

  # Only load the extensions named here, in the order given. By default all
  # extensions in vendor/extensions are loaded, in alphabetical order. :all
  # can be used as a placeholder for all extensions not explicitly named.
  # config.extensions = [ :all ]
  
  # By default, only English translations are loaded. Remove any of these from
  # the list below if you'd like to provide any of the supported languages
  #config.extensions -= [:dutch_language_pack, :french_language_pack, :german_language_pack, :italian_language_pack, :japanese_language_pack, :russian_language_pack]

 	config.extensions = [
 	  :pretty_config,
 	  :reorder,
 	  :adopt,
   	:rbac_base,
   	:parameterized_snippets,
   	:back_door,
   	:share_layouts,
   	:public_access,
   	:ckeditor_filter,
   	:page_parts,
   	:all,
   	:configuration
  	]
                       
  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_dbk_session',
    :secret      => 'REPLACE WITH SECRET'
  }  

  # Comment out this line if you want to turn off all caching, or
  # add options to modify the behavior. In the majority of deployment
  # scenarios it is desirable to leave Radiant's cache enabled and in
  # the default configuration.
  #
  # Additional options:
  #  :use_x_sendfile => true
  #    Turns on X-Sendfile support for Apache with mod_xsendfile or lighttpd.
  #  :use_x_accel_redirect => '/some/virtual/path'
  #    Turns on X-Accel-Redirect support for nginx. You have to provide
  #    a path that corresponds to a virtual location in your webserver
  #    configuration.
  #  :entitystore => "radiant:tmp/cache/entity"
  #    Sets the entity store type (preceding the colon) and storage
  #   location (following the colon, relative to Rails.root).
  #    We recommend you use radiant: since this will enable manual expiration.
  #  :metastore => "radiant:tmp/cache/meta"
  #    Sets the meta store type and storage location.  We recommend you use
  #    radiant: since this will enable manual expiration and acceleration headers.
  #config.middleware.use ::Radiant::Cache
  
  config.action_mailer.delivery_method = :sendmail
  #config.action_mailer.delivery_method = :smtp
  #config.action_mailer.smtp_settings = {:address => 'localhost',:port => 25,:domain => "www.daybreakweb.com"}
  #config.action_mailer.smtp_settings = {:address => "smtp.comcast.net",:port => 25,:domain => "www.daybreakweb.com",:authentication => :login, :user_name => 'USERNAME',:password => 'PASSWORD'}

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store # [Session::CookieStore]

  #OLD: config.action_controller.page_cache_directory = "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  config.active_record.observers = :user_action_observer

  # Make Active Record use UTC-base instead of local time
  #config.time_zone = 'UTC'

  # Set the default field error proc
  config.action_view.field_error_proc = Proc.new do |html, instance|
    if html !~ /label/
      %{<span class="error-with-field">#{html} <span class="error">#{[instance.error_message].flatten.first}</span></span>}
    else
      html
    end
  end
  
  config.log_level = :info

  #config.gem "radiant"
  config.gem 'will_paginate', :version => '~> 2.3.11', :source => 'http://gemcutter.org'  
  config.gem "mysql"
  config.gem "mongrel"
  config.gem "builder"
  config.gem "is_taggable"
  config.gem "xml-simple",      :lib => 'xmlsimple'
  config.gem "mime-types",      :lib => "mime/types",      :version => '>= 1'
  config.gem "fastercsv"
  config.gem "paperclip"
  config.gem "net-ssh",         :lib => "net/ssh",         :version => "2.0.11"
  config.gem "net-scp",         :lib => "net/scp",         :version => "1.0.2"
  config.gem "net-sftp",        :lib => "net/sftp",        :version => "2.0.2"
  config.gem "net-ssh-gateway", :lib => "net/ssh/gateway", :version => "1.0.1"
  config.gem "tzinfo"
  config.gem "uuid"
  #config.gem "rmagick", :lib => "RMagick2"
  #config.gem "mongrel_cluster" -- DO NOT INCLUDE.

  config.after_initialize do
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.uncountable 'config'
      inflect.uncountable 'series'
      inflect.uncountable 'meta'
    end
  end
end

CalendarDateSelect.format = :american

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  if html_tag =~ /<(input)[^>]+type=["'](radio|checkbox|hidden)/
    html_tag
  else
    "<em class=\"error-with-field\">#{html_tag} <small class=\"error\">&bull; #{[instance.error_message].flatten.first}</small></em>"
  end
end

require "status"

#used inside of snippets
def db_query(sql)
	ActiveRecord::Base.connection.select_all(sql)
end

#require 'iwish/memory_profiler'
#MemoryProfiler.start(:string_debug => false, :delay => 60)

require 'bleak_house' if ENV['BLEAK_HOUSE']

