module ShareLayouts
	module Tags
		include Radiant::Taggable

		tag 'if_from_rails' do |tag|
			if tag.locals.page.is_a? ShareLayouts::RailsPage
				tag.expand
			end
		end

		tag 'unless_from_rails' do |tag|
			unless tag.locals.page.is_a? ShareLayouts::RailsPage
				tag.expand
			end
		end

#TODO: determine if other stylesheets/javascripts tags already exist.
		tag 'stylesheets' do |tag|
			stylesheets = tag.locals.page.parts.select{|part| part.name == 'stylesheets'}.first.content rescue []
			stylesheets.map {|stylesheet|  "<link rel='stylesheet' type='text/css' href='/stylesheets/#{stylesheet}.css' />" }.join("\n")
		end

		tag 'javascripts' do |tag|
			javascripts = tag.locals.page.parts.select{|part| part.name == 'javascripts'}.first.content rescue []
			javascripts.map {|javascript|  "<script language='javascript' type='text/javascript' src='/javascripts/#{javascript}.js'></script>" }.join("\n")
		end
	end
end
