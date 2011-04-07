require 'railsmachine/recipes'
require 'config/recipies/my_cap_tasks'
require 'mongrel_cluster/recipes'
load 'compat'

set :use_sudo, 		false
set :user, 				"deploy"
set :password,		"{REPLACE WITH PASSWORD}"
set :application, "daybreak"
set :domain, 			"{REPLACE WITH IP-ADDRESS}"
set :deploy_to, 	"/var/www/apps/#{application}"
#set(:repository) 	{"svn+ssh://#{user}@#{domain}/var/svn/repository/#{application}/trunk"}
#set(:repository) 	{"ssh://#{user}@#{domain}/var/git/#{application}.git"}
#set :svn, 				"/usr/bin/svn"


#set :deploy_via, :copy
#set :copy_cache, true

set :repository, "."
set :scm,	:git
#set :scm, :none
set :deploy_via, :copy
set :copy_exclude, [".git", "nbproject", "conversion", "public/message", "public/series", "public/event", "public/person", "public/group", "public/page_attachments", "public/scheduling_facet", "public/invitation_facet", "tmp"]

ssh_options[:paranoid] = false
set :rails_env, 	"production"

#environment.rb

set :config_files, %w(database.yml mongrel_cluster.yml)
set :app_symlinks, %w(event group message person series scheduling_facet invitation_facet page_attachments communications resources import)

role :web, domain
role :app, domain
role :db,  domain, :primary => true
role :scm, domain

set :runner, user

