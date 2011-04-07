module ApplicationHelper
  include FileColumnHelper

	def linked_select(table, column, values, options = {})
		id = "#{table}_#{column}"
		name = "#{table}[#{column}]"
		include_blank = options[:include_blank] || false
		blank_option = options[:blank_option] || ""
		disabled = options[:disabled] || false
		is_master = options.include?(:slave)
		selected_value = eval("@#{table}").send(column)
		out = []
		out << "<select id=\"#{id}\" name=\"#{name}\"" + (is_master ? " onchange=\"linked_select(this,#{options[:slave]},true)\"" : "") + (disabled ? " disabled" : "") + ">"
		out << "<option>#{blank_option}</option>" if include_blank
		values.each do |list|
			display, value, linked_to = list
			selected = value == selected_value ? " selected" : ""
			out << "<option value=\"#{value}\" linked_to=\"#{linked_to}\"#{selected}>#{display}</option>"
		end
		out << "</select>"
		out << "<script type=\"text/javascript\">linked_select(#{options[:master]},#{id},false);</script>" if !is_master
		out.map {|o| "#{o}\n"}
	end

  def markaby(&block)
    Markaby::Builder.new({}, self, &block).to_s
  end
  
  def to_object(object)
    case object
      when String, Symbol
        object = instance_variable_get("@#{object.to_s}")
    end
    object
  end

  def show_photo(object, size = :thumb, method = 'photo', target_size = nil)
    include_javascript 'lightbox'
    include_stylesheet 'lightbox'
    object = to_object(object)
    size = size.to_s
    if object.send(method)
      link_to(image_tag(url_for_file_column(object, method, size), :class => 'photo'), url_for_file_column(object, method, target_size), :rel => :lightbox, :popup => true)
    else
      image_tag('/images/admin/no-photo.png', :alt => 'no photo', :class => 'dummy-photo')
    end
  end

	def wrap_if_error(object, method)
	  obj = instance_variable_get("@#{object}")
	  error = obj.errors.on(method)
		out = []
		out << "[" + error + "]"
		out << "<em class='error-with-field'>" if error
		out << yield
		out << "<small class='error'>&bull; #{error}</small>" if error
		out << "</em>" if error
		out.join("\n")
	end

	def to_dropdown_list (ary, start_index = 0)
		index = start_index - 1
		ary.collect{ |value| index += 1; [value, index] }
	end

	def time_period(start_at, end_at, compact = true)
		return "all day" if start_at == end_at
		period = "#{start_at.strftime('%l:%M%p').strip}-#{end_at.strftime('%l:%M%p').strip}".downcase
		period.gsub!(':00','') if compact
		period
	end

	def option_set(value_name, ary, default_value = nil)
		out = []
		out << "<ul class='option_set #{value_name}'>"
		select = params[value_name] || default_value
		selection_made = false
		ary.each do |value|
			display_as = yield(value) || value
			selected = value.to_s == select
			selection_made = true if selected
			out << "<li>" + label_tag("#{value_name}_#{value.to_s.downcase}", display_as) + radio_button_tag(value_name, value, selected) + "</li>"
		end
		out << "<li>" + label_tag("#{value_name}_", "*") + radio_button_tag(value_name, "", !selection_made) + "</li>" unless default_value
		out << "</ul>"
		out
	end

	def base_url
		"http://" + @request.server_name
	end

	def help_tip(tip)
		link_to_tip("[?]", tip)
	end

	def help_diamond(tool_tip)
		"<a class='help_diamond' title=\"#{tool_tip}\"><img src='/images/admin/help_diamond.png' alt='help' /></a>"
	end

	def pluralize(count, word)
		count.to_s + ' ' + (count == 1 ? word.singularize : word.pluralize)
	end

	def context_link(link_text, controller_name, controller_action, content_wrapper = 'strong')
		link = link_to(link_text, :controller => controller_name, :action => controller_action)
		if controller.controller_name == controller_name and controller.action_name == controller_action
			content_tag(content_wrapper, link)
		else
			link
		end
	end

	def is_admin
		if current_user
			current_user.username == 'admin'
		else
			false
		end
	end

	def wrap_if(output, content_wrapper, condition)
		if condition
			content_tag(content_wrapper, output)
		else
			output
		end
	end

	def to_check(checked)
		checked ? '<img src="/images/interface/check.gif">' : "-"
	end

	# insert HTML breaks for line breaks; similar in use to "h"
	def br(str)
		str.gsub("\n", "<br />")
	end

	def link_to_map(text, address, city = nil, state = nil, zip = nil)
		link_to text, "http://www.mapquest.com/maps/map.adp?formtype=address&country=US&popflag=0&latitude=&longitude=&name=&phone=&level=&addtohistory=&cat=&address=#{address}&city=#{city}&state=#{state}&zipcode=#{zip}".gsub(" ", "+"), :popup => true
	end

	def readonly_text(value, attributes = {})
		"<input " + attributes.to_a.collect{|attr| "#{attr[0]}='#{attr[1]}'"}.join(' ') + "readonly type=\"text\" value=\"#{value}\">"
	end

	def readonly_text_area(value, rows = 1)
		"<textarea readonly rows=\"#{rows}\">#{value}</textarea>"
	end

	def days_old(date)
		(DateTime.now - Date.parse(fmt_timestamp(date))).to_i
	end

	def row_links(model, options)
		before = options[:before] || "<td>"
		after  = options[:after ] || "</td>"
		links  = options[:links]  || []
		controller ||= options[:controller]
		controller ||= model.class.to_s.downcase
		out = []
		out << before
		edit = 'edit'
		edit = image_tag("/images/interface/rightarrow.gif", :alt => 'edit')
		delete = image_tag("/images/interface/circlestop.gif", :alt => 'delete')
		out << "#{link_to(edit, :controller => controller, :action => 'edit', :id => model.id)}"
		out << links.collect{ |link| link == 'delete' ? delete_link(model, delete) : link	}
		out << after
		out.flatten.join("\n")
	end

	def form_timestamps1(model)
		str = []
		if model.respond_to?(:created_at)
			str << "<label class=\"timestamp #{model.respond_to?(:updated_at) ? ' sticky' : ''}\"><span>Created at</span>#{fmt_timestamp(model.created_at)}</label>"
		end
		if model.respond_to?(:updated_at)
			str << "<label class=\"timestamp\"><span>Updated at</span>#{fmt_timestamp(model.updated_at)}</label>"
		end
		str.join("\n")
	end

  #TODO: determine controller from Model.
	def delete_link(model, action = 'Delete')
		link_to(action, { :controller => params[:controller], :action => 'destroy', :id => model.id }, :confirm => 'Are you sure you want to delete this record?', :method => :post)
	end

	def date_field(object_name, method, options = {})
			options.merge!(:class => 'datetime textbox')
			text_field(object_name, method, options)
	end

	def fmt_timestamp(dt)
		if dt
			dt.strftime("%m/%d/%Y %I:%M %p").gsub(" 12:00 AM", "")
		else
			""
		end
	end
end

class Date
	include ActionView::Helpers::TagHelper
	include ContentTag

	def formatted
		self.strftime("%m/%d/%Y %I:%M %p").gsub(" 12:00 AM", "")
	end

	def markup_formatted
		content_tag(:span, :class => :dated){ self.formatted }
	end
end

class Time
	include ActionView::Helpers::TagHelper
	include ContentTag

	def formatted
		self.strftime("%m/%d/%Y %I:%M %p").gsub(" 12:00 AM", "")
	end

	def markup_formatted
		content_tag(:span, :class => :dated){ self.formatted }
	end
end

class OptionBar
  attr_accessor :options, :secondary_options, :separator

  def initialize(separator = ' ')
    @separator = separator
    @options = []
    @secondary_options = []
  end

  def to_s
    markup = []
    markup << "<div class='options'>"
    unless @secondary_options.empty?
      markup << "<div class='secondary'>"
      markup << @secondary_options.join(self.separator)
      markup << "</div>"
    end
    markup << @options.join(self.separator)
    markup << "</div>"
    markup.join
  end
end

