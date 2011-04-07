module PageUrl::PageExtensions
  def full_url
  	u = []
  	p = self
  	begin
  		u << p.slug if p.slug.to_s.gsub('/','').length > 0
  		p = p.parent
  	end while p
  	'/' + u.reverse.join('/')
  end
end

