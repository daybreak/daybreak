module MarkupHelpers
  module AuthenticityToken
    def authenticity_token
      markaby do
        input(:type => "hidden", :name => "authenticity_token", :value => form_authenticity_token)
      end
    end  
  end

	module Radiant
	  class Component
  	  include ActionView::Helpers::TagHelper
	    include ActionView::Helpers::UrlHelper
	  
	    def initialize(view, controller)
	      @view = view
	      @controller = controller
	      @items = []
	    end
	    
	    def add(text)
        @items << text
	    end

	    def to_s
	      markup = []
	      markup << @items
	      markup.flatten.join("\n")
	    end
	  end	
	
	  class Actions < Component
	    def to_s
	      markup = []
	      markup << '<ul>'
	      @items.each do |item|
	        markup << '<li>' + item + '</li>'
	      end
	      markup << '</ul>'
	      markup.flatten.join("\n")
	    end
	  end

	  class UnderTabs < Component
      def add(text, params)
        @items << (current_page?(params) ? "<span class='current'>#{text}</span>" : link_to(text,  params))
      end
      
      def paginate(object)
        @items << @view.will_paginate(object)
      end
	  end

    def actions(&block)
      actions   = MarkupHelpers::Radiant::Actions.new(self, @controller)
      undertabs = MarkupHelpers::Radiant::UnderTabs.new(self, @controller)
      yield(actions, undertabs) if block_given?      
      markaby do
        br
        br
        div.actions! do
          div.pagination do
            text undertabs.to_s        
          end         
          text actions.to_s
        end
      end
    end
    
    def new_record(what, options = {}, &block)
      options = {:action => 'new', :label => add_image_tag(what) + "New #{what}"}.merge(options)    
      button_text = options.delete(:label) || what.pluralize
      link_to(button_text, options)      
    end

    def entitled(object, method = :title, options = {})
      name = "#{object}[#{method}]"
      id = "#{object}_#{method}"
      object = self.instance_variable_get("@#{object}") if object.is_a?(Symbol)
      value = object.send(method)
      options = {:id => id, :name => name, :maxlength => 255, :value => value}.merge(options)
      markaby do
        p.title do
          label(:for => id){method.to_s.titleize}
          input.textbox(options)
        end
      end
    end
    
    def component(options = {})
      markaby do
        text(render(:partial => "/admin/shared/component", :locals => {:options => options}))
      end
    end
    
    def image_exists?(src)
      path_to_image(src).include? '?'
    end
    
    def add_image_tag(what)
      image_tag("/images/admin/plus.png", :alt => "New #{what}")
    end

    def obsolete_add_image_tag(what, options = {})
      paths = ["/images/admin/new-#{what.to_s.downcase}.png", "/images/admin/plus.png"]
      image_path = paths.detect{|path| image_exists?(path)}
      options[:alt] = "New #{what}"
      options[:style] = 'position: relative; top: 10px' if image_path == paths.first
      image_tag(paths.detect{|path| image_exists?(path)}, options)
    end
    
    include MarkupHelpers::AuthenticityToken

		def timestamp(time)
		  time.strftime("%I:%M <small>%p</small> on %B %d, %Y")
		end

		def index_table(headings, records = [], fields = [], &block)
			headings ||= []
			headings = Array(headings).flatten
			markaby do
				table.index do
				  thead do
				  	tr do
							headings.each do |heading|
								th heading
							end
				  	end
				  end
				  if records.length > 0
				  	tbody do
				  		records.each do |record|
								if block_given?
									capture(&block)
								else
									index_row record, fields.dup
								end
				  		end
				  	end
				  end
				end
			end
		end

		def index_row(model, fields)
			markaby do
        tr :class => "node level-0" do
          td.page do
            span.w1 do
              a :href=> url_for(:action => 'edit', :id => model) do
                img.icon :alt => "page-icon", :src=>"/images/admin/page.png"
                span.title {model.send(fields.shift.to_sym).titleize}
              end
              desc = model.send(fields.shift.to_sym)
              if desc && desc.length > 0
	              p desc
              else
              	p.invisible "..."
              end
            end
          end
          fields.each do |field|
          	if field.kind_of? Symbol
	          	td{model.send(field)}
          	else
          		td{field}
          	end
          end
        end
			end
		end

  	def updated_stamp(model)
			markaby do
				unless model.new_record?
				  updated_by = (model.updated_by || model.created_by)
				  login = updated_by ? updated_by.login : nil
				  time = (model.updated_at || model.created_at)
				  if login or time
				    p :style=>"clear: left" do
				    	small do
				    		text "Last updated "
				    		text "by #{login} " if login
				    		text "at #{timestamp(time)} " if time
				    	end
				    end
				  end
				else
					p.clear{"&nbsp;"}
				end
			end
		end
	end

	module TabControl
		def tab_control(pages = nil, &block)
			#include_javascript 'admin/activate_tab_control' #TODO: old way
			pages ||= {}
			markaby do
			  input.page_part_index_field!(:name=>'index',:type=>'hidden',:value=>'0') #required only by Radiant scripts -- here only to prevent JavaScript error.
				div.tab_control! do
				  div.tabs.tabs! do
				    div.tab_toolbar!{""}
				  end
				  div.pages.pages! do
				  	capture(&block)
				  end
				end
			end
		end

		def tab_page(tab, &block)
			markaby do
	      div.page :id => "page_#{tab}", 'data-caption' => tab.to_s.gsub('_',' ').titleize do
					capture(&block)
				end
			end
		end

	end

	module Toggles
		def toggles(options = nil, &block)
			include_javascript 'toggles'
			include_stylesheet 'toggles'
			options ||= {}
			options[:show]  ||= false
			options[:toggler_tag]  ||= :div
			markaby do
				div :class => "togglearea #{options[:show] ? 'on' : 'off'}" do
					toggler(options)
					div.toggles do
						capture(&block)
					end
				end
			end
		end

		def toggler(options)
			options ||= {}
			options[:on]  ||= 'On'
			options[:off] ||= 'Off'
			toggler_tag = (options[:toggler_tag] || 'div').to_sym

			markaby do
				tag!(toggler_tag, :class=> 'toggler') do
					a.on do
						text options[:on]
					end
					a.off do
						text options[:off]
					end
				end
			end
		end

		def split_args(*args)
			object = args.shift
			fieldname = args.shift
			options = args.shift || {}
			[object, fieldname, standardize(options)]
		end

		def standardize(options = nil)
			options ||= {}
			options[:suppress_wrapper] = true
			options[:size] = 16 if options[:type] == :date
			options
		end

		def meta_data(&block)
			markaby do
			  div.row :id => 'extended-metadata' do
					capture(&block)
			 	end
			end
		end

		def meta_table(&block)
			markaby do
			  table.fieldset do
					capture(&block)
				end
			end
		end

		def inner_field(object, fieldname, options = nil)
			options ||= {}
			standardize options
			markaby do
				text ' &nbsp; &nbsp; &nbsp; '
				field(object, fieldname, options)
			end
		end

		def meta_row(*args, &outer_block)
			outer_block_given = block_given?
			if args.first.kind_of? String
				lbl = args.shift
				qualified = args.shift
				basic_meta_row(lbl, qualified) do
					concat(capture(&outer_block)) if outer_block_given
				end
			else
				object, fieldname, options = split_args(*args)
				standardize options
				qualified = "#{object.to_s}_#{object.to_s}".to_sym
				lbl = options.delete(:label) || fieldname.to_s.humanize.gsub(' Id', '')
				options[:label] = ''
				required = options.delete(:required)
				basic_meta_row(lbl, qualified, required) do
					field(object, fieldname, options)
					concat(capture(&outer_block)) if outer_block_given
				end
			end
		end

	private

		def basic_meta_row(lbl, qualified = nil, required = false, &block)
			markaby do
				tr do
					label_options = {:for => qualified}
					label_options = {:class => 'required'} if required
					th.label { label(label_options){ lbl }   }
					td.field { capture(&block) }
				end
			end
		end
	end
end

=begin
Markaby::Builder.class_eval do
  def row(link, desc = nil, &block)
    tr :class => 'node level-0' do
      span.w1 do
        text link
        p.descriptions{desc}
      end
      if block
        str = capture(&block)
        block = proc { text(str) }
      end
      fragment { @builder.method_missing(:text, &block) }
    end
  end    
end
=end
