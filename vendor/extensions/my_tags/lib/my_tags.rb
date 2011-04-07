module MyTags
	include Radiant::Taggable

	class TagError < StandardError; end

	tag 'base_url' do |tag|
		"http://" + request.server_name
	end

  tag 'find_page' do |tag|
    id = tag.attr['id']
    raise TagError.new("`find' tag must contain `id' attribute") unless id

    found = Page.find(id)
    if page_found?(found)
      tag.locals.page = found
      tag.expand
    end
  end

  tag 'crosslink' do |tag|
    id = tag.attr['id']
    raise TagError.new("`crosslink' tag must contain `id' attribute") unless id

    found = Page.find(id)
    if page_found?(found)
      tag.locals.page = found
    	text = tag.double? ? tag.expand : tag.render('title')
    	%{<a href="#{tag.render('url')}">#{text}</a>}
    end
  end

	tag 'flash' do |tag|
		kind = tag.attr['kind']
		markup = []
		flash = response.session['flash']
		if flash && flash.any?
			markup << "<ul id='flash'>"
			flash.each_pair do |key,value|
				if kind.nil? or kind.to_s == key.to_s
					markup << "<li class='#{key}'>#{value}</li>"
        end
			end
			markup << "</ul>"
    end
		markup.join("\n")
	end

  #legacy tag used by Edgy theme
	tag 'if_sidebar' do |tag|
		has_children = tag.locals.page.children.size > 0
		has_grandparent = (tag.locals.page.parent and tag.locals.page.parent.parent)
		tag.expand if has_children or (!has_children and has_grandparent)
	end

  #legacy tag used by Edgy theme
	tag 'unless_sidebar' do |tag|
		has_children = tag.locals.page.children.size > 0
		has_grandparent = (tag.locals.page.parent and tag.locals.page.parent.parent)
		tag.expand unless has_children or (!has_children and has_grandparent)
	end

	tag 'link_to_verse' do |tag|
		passage = tag.attr['passage']
		search_for = passage.gsub('.', ' ').gsub('  ', ' ')
		%{<a class='external' href="http://bible.gospelcom.net/passage/?search=#{search_for};&version=31;" title="Lookup #{passage}"/>#{passage}</a>}
	end

	tag 'link_to_book' do |tag|
		isbn = tag.attr['isbn']
		#tag.attr.each_pair{|key, value| }
		store_link = ["http://www.allbookstores.com/book/#{isbn}", "All Book Stores"]
		#store_link = ["http://www.bestwebbuys.com/books/compare/isbn/#{isbn}", "Best Book Buys"]
		#store_link = ["http://www.shopping.com/xFS?KW=#{isbn}&FN=Books", "Shopping.<b>com</b>pare books"]
		#store_link = ["http://www.pricegrabber.com/search_getprod.php?isbn=#{isbn}", "Price Grabber"]
		#store_link = ["http://www.pricescan.com/books/BookDetail.asp?isbn=#{isbn}", "Price Scan"]
		#store_link = ["http://isbn.nu/#{isbn}", "ISBN NU"]
		#store_link = ["http://www.bookfinder4u.com/IsbnSearch.aspx?isbn=#{isbn}&mode=direct", "Book Finder 4U"]
		#store_link = ["http://www.bestbookdeal.com/book/compare/#{isbn}", "Best Book Deal"]
		#store_link = ["http://www.aaabooksearch.com/Compare/Prices/US/#{isbn}.html", "AAA Book Search"]
		#store_link = ["http://www.fetchbook.info/compare.do?search=#{isbn}&searchBy=ISBN&Submit=Search", "Fetch Book"]
		#store_link = ["http://www.bookhq.com/compare/#{isbn}.html", "Book H.Q."]
		#store_link = ["http://www3.addall.com/New/submitNew.cgi?query=#{isbn}&type=ISBN&location=&state=&dispCurr=USD", "Add All Books"]
		#store_link = ["http://www.cheapestbookprice.com/?searchby=ISBN&search_all=1&searchfortext=#{isbn}&search.x=0&search.y=0", "Cheapest Book Price"]
		#store_link = ["http://dogbert.abebooks.com/servlet/SearchResults?imagefield.x=0&cm_re=A*Search+Box*Form&kn=#{isbn}&imagefield.y=0", "Abe Books"]
		#store_link = ["http://ebs.allbookstores.com/book/compare/#{isbn}", "Every Book Store"]
		url, store_name = store_link
		%{<a class='external' href="#{url}" title="Go to #{store_name}"/>#{tag.single? ? 'buy book' : tag.expand}</a>}
	end

	tag 'link' do |tag|
		options = tag.attr.dup
		anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
		attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
		attributes = " #{attributes}" unless attributes.empty?
		url = tag.render('url')
		url_current_page = tag.globals.page.url
		text = tag.double? ? tag.expand : tag.render('title')
		if url == url_current_page
			%{<a #{attributes}>#{text}</a>}
		else
			%{<a href="#{url}#{anchor}"#{attributes}>#{text}</a>}
		end
	end

	tag 'id' do |tag|
		tag.locals.page.id.to_s
	end
end

