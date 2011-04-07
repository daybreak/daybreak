module UserTags
	include Radiant::Taggable

	class TagError < StandardError; end

	tag 'users' do |tag|
		conditions = tag.attr['conditions']
		order = tag.attr['order'] || "name"
		tag.locals.users = User.find(:all, :conditions => conditions, :order => order)
		tag.expand
	end

	tag 'users:each' do |tag|
    options = children_find_options(tag)
    result = []
    users = tag.locals.users
    users.each do |user|
      tag.locals.user = user
      result << tag.expand
    end
    result
	end

	tag 'users:each:name' do |tag|
		tag.locals.user.name
	end

	tag 'anonymous' do |tag|
		user = request.session['user']
		tag.expand unless user
	end

	tag 'user' do |tag|
		user = request.session['user']
		tag.locals.user = user
		tag.expand if user
	end

	tag 'user:name' do |tag|
		tag.locals.user.name
	end

	tag 'user:id' do |tag|
		tag.locals.user.id
	end

	def current_user
	  user_id = self.request.session['user_id']
  	user_id ? User.find(user_id) : nil
	end

	tag 'current_user' do |tag|
  	tag.locals.current_user = current_user
  	if tag.double?
  		tag.expand
  	elsif tag.locals.current_user
	  	tag.locals.current_user.name
	  else
	    ''
	  end
  end

  tag 'current_user:id' do |tag|
  	tag.locals.current_user.id
  end

  tag 'current_user:name' do |tag|
  	tag.locals.current_user.name
  end

  tag 'current_user:email' do |tag|
  	tag.locals.current_user.email
  end

  tag 'current_user:login' do |tag|
  	tag.locals.current_user.login
  end

	tag 'if_logged_in' do |tag|
		tag.expand if tag.globals.page.request.session['user_id']
	end

	tag 'unless_logged_in' do |tag|
		tag.expand unless tag.globals.page.request.session['user_id']
	end

	tag 'if_admin' do |tag|
		tag.expand if current_user.try("admin?")
	end

	tag 'unless_admin' do |tag|
		tag.expand unless current_user.try("admin?")
	end

  def does_user_have_role?(roles)
  	return unless user = current_user
  	roles.empty? ? user.role? : roles.any?{|role| user.role?(role)}
  end

	tag 'if_role' do |tag|
		tag.expand if does_user_have_role?(tag.attr['role'].to_s.split(','))
	end

	tag 'unless_role' do |tag|
		tag.expand unless does_user_have_role?(tag.attr['role'].to_s.split(','))
	end
end

