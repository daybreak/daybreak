require 'ftools'
require 'pp'

module Symplify
	def self.locate(dir)
		ary = dir.split('/')
		ary.pop
		File.expand_path(File.join(ary.join('/'), File.readlink(dir)))
	end

	def self.target(syncpoint)
		target_and_paths(syncpoint).first
	end

	def self.mappings(paths, syncpoint, tgt, absolute_path = false)
		paths.map{|dir| Symplify::Mapping.new(File.expand_path(dir), File.expand_path(File.join(tgt, self.tailpath(dir, syncpoint))), absolute_path)}
	end

	def self.ls(syncpoint, filter = nil, &block)
		paths = Dir["#{syncpoint}/**/**"]
		paths = paths.select{|path| path.split('/').include? filter } if filter
		paths
	end

	# filter    = filter to a particular subdirectory
	# syncpoint = the pivotal folder on which we're mapping
	def self.map(syncpoint, filter, *options)
		simulate      = options.include? 's' #simulated activity only
		absolute_path = options.include? 'a' #establish relative or absolute links
		replace       = options.include? 'replace'

		target, folders = self.target_and_paths(syncpoint)
		folders = folders.select{|path| path.split('/').include? filter } if filter

		#SOMEDAY: prompt for overwriting
		for folder in folders
			paths = self.expand(*folder)
			mappings = self.mappings(paths, syncpoint, target, absolute_path)
			absolute_paths = mappings.map{|m|m.tgt.absolute_path}
			mappings.each do |m|
				symlinks = mappings.select{|x|x.symlinked}
				m.symlinked ||= :contained if symlinks.detect{|symlink| m.tgt.absolute_path.index("#{symlink.tgt.absolute_path}/")}
				m.symlinked ||= :replaced  if replace && m.tgt.exists? && m.src.exists? && !m.tgt.symlink? && self.replacable(m.tgt.absolute_path,absolute_paths)
				m.tgt.delete if !simulate && replace and m.symlinked == :replaced
				unless m.tgt.exists?
					m.symlink unless simulate || m.symlinked == :contained
					m.symlinked ||= :linked
				end
				#pp m
			end
			yield(folder, mappings) if block_given?
		end
	end

	def self.replacable(absolute_path, paths)
		nodes = absolute_path.split('/')
		last_node = nodes.pop
		parent_path = nodes.join('/')
		contains = Dir["#{absolute_path}/**"]
		contains.all?{|path| paths.include? path}
	end

private

	def self.topmost(paths)
		target = nil
		paths.each {|p|	target = p if target == nil or target.split('/').length > p.split('/').length }
		target
	end

	def self.tailpath(path, following_node)
		after = []
		is_after = false
		path.split('/').each do |node|
			after << node if is_after
			is_after = true if node == following_node
		end
		after.join('/')
	end

	def self.target_and_paths(syncpoint)
		paths = Dir["**/#{syncpoint}"] #identify pivotal folders
		target = self.topmost(paths)   #identify target folder for synchronization point
		paths.reject!{|p| p == target} #extracts target folder leaving the rest
		target = File.join(`pwd`.chomp, target)#resolve absolute path for target
		[target, paths]
	end

	def self.expand(paths)
		Dir['**/**'].select{|dir| paths.detect{|p| dir.index(p) == 0 }}
	end

	class Path
		attr_reader :absolute_path
		attr_accessor :relative_path, :path

		def initialize(absolute_path)
			@absolute_path = absolute_path
		end

		def delete
			self.directory? ? FileUtils.remove_dir(@absolute_path) : File.delete(@absolute_path)
		end

		def deleted?
			!self.exists?
		end

		def directory?
			File.directory?(@absolute_path)
		end

		def symlink?
			File.symlink?(@absolute_path)
		end

		def file?
			File.file?(@absolute_path)
		end

		def exists?
			File.exists?(@absolute_path)
		end
	end

	class Mapping
		attr_reader :src, :tgt, :link_from
		attr_accessor :symlinked

		def initialize(src_absolute_path, tgt_absolute_path, use_absolute = true)
			@use_absolute = use_absolute
			@src = Symplify::Path.new(src_absolute_path)
			@tgt = Symplify::Path.new(tgt_absolute_path)
			src_path, tgt_path = strip_common_start_path(@src.absolute_path, @tgt.absolute_path)
			@src.path = src_path
			@tgt.path = tgt_path
			@src.relative_path = relpath(@src.absolute_path, @tgt.absolute_path)
			@symlinked = :already if @tgt.symlink?
		end

		def symlink
			File.symlink(self.link_from, @tgt.absolute_path)
		end

		def link_from
			@use_absolute ? @src.absolute_path : @src.relative_path
		end

	private

		def relpath(source, target)
			s,t = strip_common_start(source.split('/'), target.split('/'))
			path = []
			(t.length - 1).times{ path << '..'}
			path << s
			path.flatten!
			path.join('/')
		end

		def strip_common_start_path(path1, path2)
			p1,p2 = strip_common_start(path1.split('/'),path2.split('/'))
			[p1.join('/'), p2.join('/')]
		end

		def strip_common_start(ary1, ary2)
			while ary1[0] == ary2[0]
				ary1.shift
				ary2.shift
			end
			[ary1, ary2]
		end
	end
end

namespace :symlinks do
	task :default => :list

	desc "List all symlinks"
	task :list do
		symlinks = Symplify.ls(ENV['on'] || 'public').select{|p|File.symlink?(p)}
		symlinks.each do |path|
			location = Symplify.locate(path)
			broken = !File.exist?(location)
			puts " #{broken ? '!' : '@'} => #{path}"
		end
		puts 'No symlinks' if symlinks.empty?
	end

	desc "List broken symlinks"
	task :broken do
		symlinks = Symplify.ls(ENV['on'] || 'public').select{|p|File.symlink?(p)}
		broken_symlinks = symlinks.reject{|path| File.exist?(Symplify.locate(path)) }
		broken_symlinks.each {|path| puts " ! => #{path}"}
		puts 'No broken symlinks' if broken_symlinks.empty?
	end

	desc "Remove broken symlinks"
	task :cleanup do
		options  = (ENV['opts'] || '').split(',')
		git = options.include? 'git'
		symlinks = Symplify.ls(ENV['on'] || 'public').select{|p|File.symlink?(p)}
		broken_symlinks = symlinks.reject{|path| File.exist?(Symplify.locate(path))}
		broken_symlinks.each do |path|
			system("#{git ? 'git ' : ''}rm #{path}")
			puts "removed => #{path}"
		end
		puts 'No broken symlinks to remove' if broken_symlinks.empty?
	end

	desc "List existing symlinks by folder"
	task :mappings, :filter do |t,args|
		none = false
		Symplify.map(ENV['on'] || 'public', args[:filter], 's') do |folder, mappings|
			symlinks = mappings.select{|m| m.tgt.symlink?}
			puts ''
			puts (symlinks.empty? ? "No symlinks for #{folder}." : "Symlinks for #{folder}:")
			symlinks.each {|m| puts " @ => #{m.tgt.path}"}
		end
	end

	#TODO: check replaceables are identical before deleting
	#TODO: filter, optional regex support
	#TODO: test with ckeditor_filter
	#example: `rake symlink:map[filter] [opts=s,a,overwrite] [on=public]`
	desc "Symlink assets from subfolder to public"
	task :map, :filter do |t,args|
		options   = (ENV['opts'] || '').split(',')
		simulate  = options.include? 's'
		long      = options.include? 'l'
		flags     = {:linked => 's', :replaced => 'S', :contained => '"', :already => '@'}
		tally     = lambda{|symlinked| [:linked, :replaced].include?(symlinked)}
		Symplify.map(ENV['on'] || 'public', args[:filter], *options) do |folder, mappings|
			links = mappings.select{|c| tally.call(c.symlinked) }.length
			puts "#{simulate ? 'Anticipate' : 'Created'} #{links} symlink(s) for #{folder}."
			for m in mappings
				tell = [' ']
				tell << (flags[m.symlinked] || ' ')
				tell << ' => '
				tell << m.tgt.path
				tell << '/' if m.src.directory?
				puts tell.join if long || tally.call(m.symlinked)
			end
			puts ''
		end
	end

	desc "Symlinks legend"
	task :legend do
		puts 'Legend:'
		puts ' s = symlink (new)'
		puts ' S = symlink (replaced)'
		puts ' @ = symlink (existing)'
		puts ' ! = symlink (broken)'
		puts ' " = asset within symlinked folder'
	end
end

