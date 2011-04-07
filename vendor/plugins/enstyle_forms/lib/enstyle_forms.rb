module ContentTag
	def content_tag(name, content_or_options_with_block = nil, options = nil, &block)
		if block_given?
			options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
			content = block.call
		else
			content = content_or_options_with_block
		end
		content_tag_string(name, content, options)
	end
end

class Hash
  def absorb(hash)
      hash.each_pair do |key, value|
        self[key] = value unless self.include?(key)
      end
  end
end

module Enstyle
  class Config
    cattr_reader :default_options, :default_composed_of, :valid_options, :field_types, :style_wrapper_with, :style_input_with

    @@style_wrapper_with  = [:what, :type, :method, :datatype]
    @@style_input_with    = [:required]
    @@valid_options       = [:readonly, :wrapper, :include_meta, :type, :label, :format, :required, :what]
    @@default_options     = { :readonly => false, :wrapper => :div }
    @@default_composed_of = [:wrapper, :input, :label, :hint ]
    @@field_types = { :text     => {:method_name => :text_field          , :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true }, :pass => [:max_length] },
                      :textarea => {:method_name => :text_area           , :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true, :rows => nil, :cols => nil } },
                      :dropdown => {:method_name => :select              , :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true }, :pass => [:disabled] },
                      :checkbox => {:method_name => :check_box           , :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true } },
                      :choice   => {:method_name => :choice_set          , :composed_of => [:wrapper, :input, :hint ]        , :default_options => { :readonly => false, :wrapper => :div, :include_meta => true }, :pass => [:label] },
                      :hidden   => {:method_name => :hidden_field        , :composed_of => [:input]                          , :default_options => { :readonly => false, :wrapper => :div, :include_meta => true } },
                      :password => {:method_name => :password_field      , :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true } },
                      :date     => {:method_name => :calendar_date_select, :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true } },
                      :imagebox => {:method_name => :image_box           , :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true } },
                      :file     => {:method_name => :file_column_field   , :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true } },
                      :display  => {:method_name => :display_value       , :composed_of => [:wrapper, :input, :label, :hint ], :default_options => { :readonly => false, :wrapper => :div, :include_meta => true }, :pass => [:format] }
                    }

  end

  module Extends
    def enstyle(options = {})

      include Enstyle::Helpers
      if options[:tags] == :override
        Enstyle::Config.field_types.each_pair do |field_type, attributes|
          method_name = attributes[:method_name]
          eval("alias_method :plain_#{method_name.to_s}, :#{method_name.to_s}")
          define_method method_name do |*args|
             options = args.last
             options[:type] = field_type if options.kind_of?(Hash)
             markup = eval("field(*args)")
             markup
          end
        end
      end
    end
  end

	module Helpers
		include ContentTag
    include ActionView::Helpers::FormHelper
    include ActionView::Helpers::FormOptionsHelper
    #include FileColumnHelper

    def enstyle_form_for(name, options = nil, &block)
      object = options.delete(:object) || eval("@#{name.to_s}")
			options = (options || {}).merge(:builder => EnstyleFormBuilder)
      actions = options.delete(:actions)
      multipart = options.delete(:multipart)
      options[:html] = (options[:html] || {}).merge(:class => name.to_sym)
      options[:html].merge!(:multipart => multipart) if multipart
      options[:url] ||= {:action => actions.first, :id => object.id } if object
      begin
        options[:url][:action] = options[:url][:action].to_s.downcase
        rescue
      end
      options[:append] ||= ''
      options[:append] << controls(name, actions) if actions
      extended_form_for(name, object, options, &block)
		end

    def extended_form_for(object_name, *args, &proc)
      raise ArgumentError, "Missing block" unless block_given?
      options = args.last.is_a?(Hash) ? args.pop : {}
      prepend = options.delete(:prepend)
      append = options.delete(:append)
      concat(form_tag(options.delete(:url) || {}, options.delete(:html) || {}))
      concat(prepend) unless prepend.blank?
      fields_for(object_name, *(args << options), &proc)
      concat(append)  unless append.blank?
      concat('</form>')
    end

		alias meta_form_for enstyle_form_for

    def markaby(&block)
      Markaby::Builder.new({}, self, &block).to_s
    end

    def form_remote(options = {}, &block)
      options[:form] = true
      options[:method] ||= :post
      options[:onsubmit] = (options[:onsubmit] ? options[:onsubmit] + "; " : "") + "#{remote_function(options)}; return false;"
      options.delete_if { |key, | [:form, :complete, :loading, :update].include?(key) }
      options[:action] ||= url_for(options.delete(:url))
      markaby do
        text form(options, &block)
      end
    end

		def to_label_markup(object_name, method, options)
			options[:label] ||= method.to_s.humanize.gsub(' Id', '') #eliminate ID from the end -- e.g. person_id => 'Person'
			label_text = options[:label]
			label_text.length > 0 ? (lbl(object_name, method) { label_text }) : nil
		end

		def lbl(object_name, method, text = nil, options = {})
			id = to_id(object_name, method)
			content_tag(:label, :for => id ) { text || (yield if block_given?) }
		end

		def column_attributes(object_name, method)
			column = eval("@#{object_name}.column_for_attribute('#{method}')") rescue nil
			yield(column) if block_given? and column
			column
		end

    #a fact for display on the form often with an accompanying label
		def label_for(label, options = {})
			wrapper = options.delete(:wrapper) || :div
			on = options.delete(:on) # is the label on the left or the right?
			id = options.delete(:id)
			label_for = options.delete(:for)
			label_markup = content_tag(:label, {:for => label_for}){ label }
      options.absorb({ :what => :field })
      options[:class] = extract_style(nil, nil, Enstyle::Config.style_wrapper_with, options)
			markup = []
			markup << label_markup
			markup << yield(label_for)
			content = (on == :right ? markup.reverse : markup).join('')
      filter_options options
			if wrapper
				options[:id] = id if id
				content_tag(wrapper, options){ content }
			else
				content
			end
		end

		def hint(text = nil)
			hint_text = (text || yield) rescue nil
			hint_text ? content_tag(:small, :class=>:hint){ hint_text } : nil
		end

		def block_tag(tag, options = {}, &block)
		  concat(content_tag(tag, capture(&block), options))
		end

		def expanding_box_toggle(expand, collapse, box_id)
			onclick, more_id, less_id = expanding_toggle(box_id)
			content_tag(:small, :class=> 'expanding_toggle'){ content_tag(:a, :onclick => onclick, :id => more_id, :class => 'expanding-box expand' ){ expand } + content_tag(:a, :onclick => onclick, :id => less_id, :class => 'expanding-box collapse', :style => "display: none;"){ collapse } }
		end

    def expanding_toggle(box_id)
			more_id = "more-#{box_id}"
			less_id = "less-#{box_id}"
			["javascript:$('#{box_id}','#{more_id}','#{less_id}').invoke('toggle');", more_id, less_id]
    end

		#TODO: make into a component, with it's own stylesheet/javascript
		def expanding_box(expand = 'Expand', collapse = 'Collapse', options = {}, &block)
			include_stylesheet 'expanding_box'
			is_open = options[:is_open] == true
			@@expanding_box_number ||= 0
			@@expanding_box_number += 1
			box_id = "expanding-box-#{@@expanding_box_number}"
			toggle_location = options[:toggle_location] || :bottom
      onclick = expanding_toggle(box_id)[0]
			concat(expanding_box_toggle(expand, collapse, box_id)) if toggle_location == :top
			concat(content_tag(:div, :id=> box_id, :class => :row, :style => 'display: none;'){capture(&block)})
			concat(expanding_box_toggle(expand, collapse, box_id)) if toggle_location == :bottom
			concat(content_tag(:script, :type=> 'text/javascript'){onclick}) if is_open
			concat('')
		end

		def more_less_box(is_open = false, &block)
			expanding_box('More', 'Less', {:is_open => is_open}, &block)
		end

		#alias fieldset fieldset_tag

		def range(object_name, method, method_start, method_end, options = {})
      options.absorb({ :between_word => ' to ', :label => method.to_s.humanize, :wrapper => :div, :type => :text })
			wrapper = options[:wrapper]
			field_type = options[:type]
      options[:what] = [:field, :range]
      wrapper_style = extract_style(object_name, method, Enstyle::Config.style_wrapper_with, options).join(' ')
			between_word = options.delete(:between_word)
			markup = []
			markup << to_label_markup(object_name, method_start, options)
			markup << field(object_name, method_start, {:id => "#{object_name.to_s}_#{method_start}", :wrapper => :div, :label => '', :wrapper_style => :start, :type => field_type })
			markup << content_tag(:div, :class => :between_word ){ between_word }
			markup << field(object_name, method_end, {:id => "#{object_name.to_s}_#{method_end}", :wrapper => :div, :label => '', :wrapper_style => :end, :type => field_type })
			content_tag(wrapper, :class=> wrapper_style){ markup.join("\n") }
		end

		alias rng range

#TODO: pass all values along to a field_layout method (delegate) to allow overridding layouts.

		# OPTIONS
		# :label => "Label Text"
		# :required => true or false
		# :type => :text or :file or :text_area or :password or :hidden or :check_box
		# :hint => "Short entry hint or example"
		def field(*args)
      has_options = args.last.kind_of?(Hash)
      args << {} unless has_options #add on options defined here.
      options = args.last
      args[0] = args[0].to_s
      args[1] = args[1].to_s
      object_name = args[0]
      method = args[1]
			object_name = object_name.to_s
			method = method.to_s
			#id = to_id(object_name, method)
      options.absorb({ :type => :text, :what => :field })
			type = options[:type]
      attributes = Enstyle::Config.field_types[type.to_sym]
      method_name = attributes[:method_name] || :text_field

      if method_name == :select
        choices = options.delete(:choices)
        args.insert(2, choices) if choices
      end

      composed_of = attributes[:composed_of]
      options.absorb(attributes[:default_options] || {})
			options[:label] ||= method.to_s.humanize.gsub(' Id', '')
			suppress_wrapper = options.delete(:suppress_wrapper) || false
      pass = attributes[:pass] || []
			#readonly = options[:readonly] #TODO: do something with this value?
			options[:disabled] = options[:readonly] if options.include? :readonly
			format = options[:format] #TODO: implement
			#required = options[:required]
			input_style = extract_style(object_name, method, Enstyle::Config.style_input_with, options).join(' ')
      wrapper_style = extract_style(object_name, method, Enstyle::Config.style_wrapper_with, options).push(options.delete(:wrapper_style)).flatten.join(' ')
      wrapper = options[:wrapper] if composed_of.include?(:wrapper) && !suppress_wrapper
			label_markup = to_label_markup(object_name, method, options) if composed_of.include?(:label)
			hint_markup = hint(options.delete(:hint)) if composed_of.include?(:hint)
      before_markup = options.delete(:before)
      #before_markup = "<span class='before'>#{before_markup}</span>" if before_markup
      after_markup = options.delete(:after)
      #after_markup = "<span class='after'>#{after_markup}</span>" if after_markup

      column_attributes(object_name, method) do |c|
        default_value = c.default #TODO: use default
        #options[:maxlength] = c.limit
      end

      filter_options options, pass
      options[:class] = input_style unless input_style.empty?

      input_markup = if block_given?
        yield
      elsif options.has_key?(:content)
        options.delete(:content)
      else
        eval("#{method_name}(*args)")
      end

      markup = []
      markup << before_markup
			markup << label_markup
			markup << input_markup
			markup << hint_markup
      markup << after_markup
      markup.compact!

			if composed_of.include?(:wrapper) && !suppress_wrapper
				content_tag(wrapper, :class => wrapper_style){ markup.join("\n") }
			else
				markup.join("\n")
			end
		end

		alias fld field

		#TODO: add 'format' handling to "field" and here:
    def display_value(object_name, method, options = {})
			format = options.delete(:format)
			format = format.to_s if format
			value = to_value(object_name, method)
			value = Date.parse(value.to_s).strftime(format).gsub(" 12:00 AM", "") rescue value
			value ||= ''
			value = value.to_s.humanize if format == 'humanize'
			content_tag(:div, :class => :value){ value.to_s }
    end

		def choice_set(object_name, method, options = {})
      choices = []
			values = options[:choices] || []
			values.each_pair{ |key, value| choices << (content_tag(:label){ radio_button(object_name.to_s, method, key) + value } ) }
			input_markup = content_tag(:ul){choices.map{|choice| content_tag(:li){choice}}}
      nowrap = options.has_key?(:nowwrap)
      label = options[:label] || ""
      if nowrap
        input_markup
      else
        content_tag(:fieldset){ content_tag(:legend){ label + ":" } + input_markup  }
      end
		end

#		def choice_id_set(object_name, method, values, options = {})
#			choices = []
#			values.each_with_index { |record, index| choices << (content_tag(:label){ check_box("#{method}[#{index}]", record.id) + record.name } ) }
#			content_tag(:ul){choices.map{|choice| content_tag(:li){choice}}}
#		end

    def flash_messages
      markaby do
				if flash.any?
					ul.flash! do
						flash.each_pair do |key, value|
							li(:class => key){value}
						end
          end
        end
      end
    end
    
		def controls(object_name, *actions)
      actions = [:update, :delete] if actions.empty?
      actions.flatten!
      actions.map!{|action| action.to_s }
			model = eval("@#{object_name.to_s}")
			primary_action = actions.shift
			primary_action = 'Update' if primary_action == 'edit'
			markup = []
			markup << submit_tag(primary_action, :class => 'primary_action button' ) if primary_action.length > 0
			actions.each do |action|
        case action.downcase
          when 'delete'
            markup << delete_link(model, action) unless primary_action.downcase == 'create'
          when 'list', 'index', 'new'
            markup << link_to(action, :action => action.downcase)
          when 'copy'
            markup << link_to(action, :action => action.downcase, :id => params[:id])
          when 'back', 'cancel'
            markup << link_to(action, request.env['HTTP_REFERER'])
          else
            markup << action
				end
				markup << "&nbsp; "
			end
			content_tag(:p, :class=> :buttons){ markup.join("\n") }
		end

  private
		def to_id(object_name, method)
			"#{object_name.to_s}_#{method.to_s}"
		end

		def to_value(object_name, method)
			eval("@#{object_name.to_s}.#{method.to_s}")
		end

		def extract_style(object_name, method, style_for, options = {})
      info = {:type => options[:type], :what => options[:what], :method => (method.to_sym rescue nil), :required => options[:required]}
      unless object_name.blank?
        column_attributes(object_name, method) do |c|
          info[:datatype] = c.type.to_sym
          info[:required] ||= !c.null
        end
      end
      info[:required] = (info[:required] == true ? :required : nil)
      info.delete_if{ |key,value| value == nil }
      classes = []
      style_for.each do |style|
        classes << info[style] if info.has_key?(style)
      end
      classes.flatten.compact.map{|style| style.to_sym }
		end

    def filter_options(options, pass = [])
      #some options aren't to be passed
      options.each_key do |option|
        if Enstyle::Config.valid_options.include?(option)
          options.delete(option.to_sym) unless pass.include?(option.to_sym)
        end
      end
    end
	end
end

module ApplicationHelper
  extend Enstyle::Extends
  enstyle
end

class EnstyleFormBuilder < ActionView::Helpers::FormBuilder
  #expose all helpers
  def method_missing(method_name, *args, &block)
    @template.send(method_name, @object_name, *args, &block)
  end
end

