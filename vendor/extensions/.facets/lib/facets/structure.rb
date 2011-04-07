require 'active_support'
require 'iwish/hash'

module Facets
  def self.include_assets
    [Admin::PagesController, Admin::SnippetsController].each do |c|
      c.class_eval do
        def include_facets_assets
          include_stylesheet 'admin/facets'
          include_javascript 'admin/facets' #TODO: implement
        end
        before_filter :include_facets_assets
      end
    end
  end

  class Facet
    attr_reader :parent, :model, :facets

    def initialize(model, facets)
      @model   = model
      @fields  = Fields.new(self)
      @parts   = Parts.new(self)
      @facets  = facets
      @mimic   = lambda{}
    end

    def fields(&block)
      @fields.instance_eval(&block) if block
      @fields
    end

    def parts(&block)
      @parts.instance_eval(&block) if block
      @parts
    end

    def model(&block)
      @model.class_eval(&block) if block
      @model
    end

    def association_id
      @model.to_s.underscore
    end

    def mimic(&block)
      @mimic = block if block_given?
      @mimic
    end
  end

  class Identifiable
    attr_reader :name

    def initialize(name, options = nil)
      raise "Identifiables must be named using a string or symbol" unless name.is_a?(String) || name.is_a?(Symbol)
      raise "Identifiables cannot be anonymous" if name.to_s.length == 0
      options ||= {}
      @name = name
      @label = options.delete(:label)
      @options = options
    end

    def label
      @label || @name.to_s.humanize
    end

    def logger
      Rails.logger
    end
  end

  class Group < Identifiable
    attr_reader :state
    attr_reader :context

    STATES = [:data, :expanded, :collapsed]

    def initialize(name, options = nil)
      options ||= {}
      @state = options.delete(:state).try(:to_s).try(:to_sym)
      raise "Invalid state :#{@state} -- valid options are #{STATES.map{|c|':'+c.to_s}.join(', ')}" if @state and !STATES.include?(@state)
      @context = options.delete(:context)
      super
    end

    def nodes
      n = []
      n << self.context.try(:map){|g|g.name}
      n << self.name
      n.flatten.compact.map{|n|n.to_s}
    end

    def descriptors
      [self.name, self.state].compact.map{|descriptor|descriptor.to_s}
    end

    def path
      self.nodes.join('/')
    end
  end

  class Grouping
    attr_reader :group, :elements

    def initialize(group, elements = [])
      @group = group
      @elements = elements
    end

    def descriptors
      @group.descriptors
    end
  end

  class Content < Identifiable
    attr_writer :status

    def initialize(name, options = nil)
      @status = options.delete(:status)
      super
    end

    def status
      @status || :use
    end
  end

  class Part < Content
  end

  class Parts < ::Array
    def initialize(facet)
      @facet = facet
      super()
    end

    def add(part_name, options = {})
      self << Part.new(part_name, options)
    end

    def remove(part_name)
      self.add(part_name, :status => :omit)
    end
  end

  class Field < Content
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::JavaScriptHelper
    include ActionView::Helpers::FormOptionsHelper
    include ActionView::Helpers::AssetTagHelper
    include CalendarDateSelect::FormHelpers
    include FileColumnHelper

    attr_reader :input, :column, :section, :group, :facet, :required, :type, :description, :default, :classes, :as

    def initialize(name, options = nil)
      #TODO: derive input type if not provided
      defaults = {:input => :text, :section => :meta}
      options.replace(defaults.merge(options || {}))
      options.export(:input,:column,:section,:description,:default,:group,:facet,:type,:required,:classes).implant(self)
      @as = options[:as] || name
      @classes = [*@classes]
      @default  ||= @column.try(:default)
      @type     ||= @column.try(:type)
      @required ||= :required if @column && !@column.null
      super
      logger.warn "Consider using a part for #{name} in lieu of a textarea facet"  if @input == :textarea
    end

    def qualified_name
      "page[#{self.name}]"
    end

    def nodes
      ((self.group.try(:nodes) || []) + [self.name]).flatten.compact.map{|n|n.to_s}
    end

    def path
      self.nodes.join('/')
    end

    #NOTE: Considered checking for a validates_presence_of to determine required, but this would have necessitated http://github.com/redinger/validation_reflection
    def descriptors
      [self.name, self.type, self.required, self.classes].flatten.compact.map{|descriptor|descriptor.to_s}
    end

    def location
      n = self.nodes
      n.pop
      n.join('/')
    end

    def dom_id
      "page_#{self.name}"
    end

    def error(object)
      associated = object.send(self.facet.association_id)
      associated.errors[self.name.to_s] if associated
    end

    def label_tag
      super(self.dom_id, self.label)
    end

    #TODO: test file_column with actual photo -- may be failing locally due to broken rmagick installation
    #TODO: cannot save unchecked checkbox -- use jquery to manage hidden checkbox fields
    def input_tag(object, submitted_params)
      options = @options.dup
      submitted_value = object.errors.empty? ? nil : ::NullifyEmptyStrings.nullify(submitted_params && submitted_params['page'] ? submitted_params['page'][self.name] : nil)
      current_value = object.send(self.name)
      current_value = current_value.strftime("%m/%d/%Y %I:%M %p").gsub(' 0', ' ') if current_value.is_a?(Time) #TODO: make a type-specific filter
      default_value = object.new_record? ? @default : nil
      value = [submitted_value, current_value, default_value].detect{|v|!v.nil?}
      logger.info "The input value for #{self.name} is " + (value.nil? ? "blank" : value.to_s)
      tag = nil
      tag ||= check_box_tag(self.qualified_name, "1", value, options) if @input == :checkbox #TODO: fix -- broken when unchecked
      tag ||= select('page', self.name, [["No", 'false'],["Yes", 'true']], options.merge(:selected => value.to_s), options.delete(:html_options) || {}) if @input == :yes_no
      tag ||= text_area_tag(self.qualified_name, value, options) if @input == :textarea
      tag ||= calendar_date_select_tag(self.qualified_name, value, options.merge(:time => true)) if @input == :datetime
      tag ||= calendar_date_select_tag(self.qualified_name, value, options) if @input == :date
      tag ||= select('page', self.name, options.delete(:choices), options.merge(:selected => value), options.delete(:html_options) || {}) if @input == :dropdown
      tag ||= file_column_field('page', self.name, options) if @input == :file
      tag ||= text_field_tag(self.qualified_name, value, options)
      tag
    end
  end

  class Fields < ::Array
    def initialize(facet)
      @section = nil
      @context = []
      @facet = facet
      super()
    end

    def add(field_name, options = nil)
      column = @facet.model.columns.detect{|col| col.name == field_name.to_s }
      field = Field.new(field_name, (options || {}).set(:column, column).set(:section, @section).set(:group, @context.last).set(:facet, @facet))
      self << field
      field
    end

    def remove(field_name)
      field = self.detect{|field| field.name == field_name.to_s}
      field.status = :omit if field
      field
    end

    def section(name, &block)
      remember = @section
      current = @section = name
      self.instance_eval(&block) if block_given?
      @section = remember
      current
    end

    def group(name, options = nil, &block)
      options ||= {}
      qualified_name = (@context.map{|g|g.name} + [name]).join('/')
      current = @facet.facets.group_index[qualified_name] || Group.new(name, options.merge(:context => @context.dup))
      @facet.facets.group_index[qualified_name] = current
      @context << current
      self.instance_eval(&block) if block_given?
      @context.pop
    end
  end

  class Collection < ::Array
    attr_reader :group_index

    def initialize
      @group_index = {}
    end

    #FEATURE: includes admin stylesheets named according to the facet association.
    def include_stylesheets(controller)
      self.each{|facet| controller.include_stylesheet "admin/#{facet.association_id}"}
    end

    def fields(options = {})
      f = self.each.map{|facet| facet.fields}.flatten
      f = f.select{|field|field.status == (options[:status] || :use)}
      f = f.select{|field|field.section == options[:section]} if options[:section]
      f = f.select{|field|field.section.is_a?(String)} if options[:entitled]
      f
    end

    def groups(options = {})
      self.fields(options).select{|field|field.group}.uniq
    end

    #name may be qualified or not
    def group(name, options = {})
      @group_index[name] || self.groups(options).detect{|group|group.name == name}
    end

    def grouped(options = {})
      elements = []
      self.fields(options).each_with_index do |field, idx|
        target = find_target(field.location, field.location, elements)
        if options[:cluster_fields]
          grouping = target.detect{|e|e.is_a?(Grouping)}
          target.insert(target.index(grouping), field) if grouping
          target.push(field) unless grouping
        else
          target.push(field)
        end
      end
      elements
    end

  private

    def find_target(path, subpath, array)
      target = array
      if subpath.length > 0
        nodes    = subpath.split('/')
        name     = nodes.shift
        subpath  = nodes.join('/')
        grouping = array.select{|item|item.is_a?(Grouping)}.detect{|grouping|grouping.group.name.to_s == name.to_s}
        if grouping
          target = find_target(path, subpath, grouping.elements)
        else
          grouping = Grouping.new(self.group(path))
          array.push(grouping)
          target = grouping.elements
        end
      end
      target
    end
  end
end

