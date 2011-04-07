module Campuses
  module Tags
	  include Radiant::Taggable

	  class TagError < StandardError; end

    ::CampusesExtension::CAMPUSES.each do |campus|
	    tag campus do |tag|
	      tag.expand if tag.name == tag.globals.page.campus
	    end
	  end

	  tag 'lost' do |tag|
	    tag.expand unless tag.globals.page.campus
	  end

	  tag 'campus_content' do |tag|
		  part = campus_part(tag, tag.attr['part'] || 'body')
		  tag.attr['part'] = part.name if part
		  tag.render('content', tag.attr)
	  end

	  tag 'if_campus_content' do |tag|
	   	tag.expand if [*tag.attr['part'].split(',')].any?{|part| campus_part(tag, part || 'body')}
	  end

	  tag 'unless_campus_content' do |tag|
	  	tag.expand unless [*tag.attr['part'].split(',')].any?{|part| campus_part(tag, part || 'body')}
	  end

	  def campus_part(tag, name)
		  campus_specific_name = "#{tag.locals.page.campus}:#{name}"
		  tag.locals.page.parts.detect{|part|part.name == campus_specific_name} || tag.locals.page.parts.detect{|part|part.name == name}
	  end

	  def campus
		  self.request.cookies['campus']
	  end
  end
end

