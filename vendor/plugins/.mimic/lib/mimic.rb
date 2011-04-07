require 'extend/forwardable'

module Mimic
  include Forwardable

	#SOMEDAY: manage/combine @attributes with the merged ones
	module Attributes
    def extended_attributes
      attributes.merge(delegated_attributes)
    end

    def delegated_attributes
      props = {}
      self.class.mimics.values.each do |mimic|
        mimic.delegated.reject{|method,method_aliased| method_aliased.to_s =~ /=$/ }.each{|method, aliased_method| props[aliased_method.to_s] = self.send(aliased_method)}
      end
      props
    end
	end

  module NestedRecord
    attr_reader :association, :ignored_attributes

    def before_aspects
      me = self
      association_id = self.association_id
			@association = @model.reflect_on_association(accessor)
     	@nested_model = "::#{accessor.to_s.camelize}".constantize
     	@ignored_attributes = Set.new
     	self.ignore_attributes(self.reciprocal_association.fk)
     	#SOMEDAY: implement construct? in addition to construct
      self.construct do |method, *args|
      	existing = target = self.send(association_id)
        target ||= self.send("build_#{association_id}")
				target.send("#{me.reciprocal_association.name}=", self) unless target.send(me.reciprocal_association.name) #TODO: the native association_collection.build methods (et al) should assign the reciprocal association (like this) but don't.
        puts "Constructed #{target.class}." unless existing
        target
      end
      self.deconstruct? do |parent|
				target           = parent.send(association_id)
				constructed      = !target.nil?
				unsaved          = target.try('new_record?')
				association_free = !self.associations?(target)
				value_free       = !self.values?(target)

	      logger.debug "May #{parent.class} deconstruct #{association_id}? (All replies must be 'true'.)"
	      logger.debug "  Constructed?      #{constructed}"
	      logger.debug "  Unsaved?          #{unsaved}"
	      logger.debug "  Association free? #{association_free}"
	      logger.debug "  Value free?       #{value_free}"

        constructed && unsaved && association_free && value_free
      end
      self.deconstruct do |parent|
        parent.send("#{association_id}=", nil)
      end
    	self.model.class_eval do
    		#NOTE: it often makes sense to code the following:
    		#    validates_presence_of :your_nested_model
    		#    validates_associated  :your_nested_model
    	  before_validation do |record| #eliminate a meaningless nested_model
    	    me.deconstruct(record)
    	  end
    	end
    end

		def after_aspects
			unless self.delegated?
				self.delegate_attributes
				self.delegate_associations
			end
		end

		#ignored attributes are not factored into the deconstruct? check.
    def ignore_attributes(*attributes)
      @ignored_attributes.merge(attributes.map{|attribute|attribute.to_sym})
    end

    #returns all associations other than the reciprocal one (if defined)
    def nested_associations
    	self.nested_model.reflect_on_all_associations.reject{|a| a == self.reciprocal_association}
    end

		#TODO: the polymorphic check could be safer.
    def reciprocal_association
      reciprocal_macro = {:has_one=>:belongs_to, :belongs_to=>:has_one}[self.association.macro]
			other_model = self.association.name.to_s.camelize.constantize
      @reciprocal_association ||= other_model.reflect_on_all_associations.detect{|a| a.macro == reciprocal_macro && (a.options[:polymorphic] || self.model.new.is_a?(a.related_model))}
      def @reciprocal_association.fk
        self.options[:foreign_key] || "#{self.name}_id".to_sym
      end
      @reciprocal_association
    end

    def association_id
      self.accessor
    end

    def associations?(record)
	    return nil unless record
      !self.nested_associations.map{|a|[*record.send(a.name)]}.flatten.compact.empty?
    end

    def values?(record)
    	return nil unless record
      !record.attributes.to_a.reject{|k,v|self.ignored_attributes.include?(k.to_sym)}.all?{|key,value|value.nil? || value == self.default_value(key) || (value.is_a?(String) && value.strip.length == 0)}
    end

    def default_value(attribute)
    	self.nested_model.columns.detect{|c|c.name == attribute.to_s}.try(:default)
    end

		def delegate_associations(options = {:reciprocal => true})
    	self.nested_associations.each do |a|
				aliased_name = apply_prefix(options[:prefix], a.name)
				self.delegate "#{a.name}".to_sym => aliased_name.to_sym
				self.delegate "#{a.name}=".to_sym => "#{aliased_name}=".to_sym if [:belongs_to, :has_one].include?(a.macro)
    		a.related_model.def_lazy_delegator(self.model_name, &@construct) if options[:reciprocal]
    	end
		end

    def delegate_attributes(options = {})
    	except = options[:except] || []
    	@nested_model.columns.reject{|column| except.include?(column.name)}.each do |column|
    	  unless @model.columns.detect{|c|c.name == column.name} #don't overwrite existing attributes
					aliased_name = apply_prefix(options[:prefix], column.name)
					self.delegate "#{column.name}=".to_sym => "#{aliased_name}=".to_sym
					self.delegate "#{column.name}".to_sym => "#{aliased_name}".to_sym
    	  end
    	end
    end

	private

		def apply_prefix(prefix, name)
			name = name.to_s
			name = "#{prefix}_#{name}" if prefix && !Regexp.new("^#{prefix}").match(name)
			name
		end
  end

  class Base
    attr_reader :model, :nested_model, :accessor, :delegated

    def initialize(model, accessor, options = {}, &block)
      logger.info "#{model} mimicks #{accessor}"
      mixin = options[:extend]
      @model = model
      @accessor = accessor
      @delegated = {}
      self.instance_eval{extend mixin} if mixin
			self.construct{self.send(accessor)}
			self.deconstruct?{}
			self.deconstruct{}
			self.before_aspects if self.respond_to? :before_aspects
      self.instance_eval(&block) if block_given?
      self.after_aspects  if self.respond_to? :after_aspects
    end

    def self.logger
      @@logger ||= nil
    end

    def self.logger=(value)
      @@logger = value
    end

    def logger
      Base.logger
    end

    def model_name
      (self.reciprocal_association.name rescue self.model).to_s.underscore
    end

    def construct(&block)
      @construct = block if block_given?
      @construct
    end

    def deconstruct?(parent = nil, &block)
      @may_deconstruct = block if block_given?
      @may_deconstruct.call(parent) if parent
    end

    def deconstruct(parent = nil, &block)
      @deconstruct = block if block_given?
      @deconstruct.call(parent) if parent && self.deconstruct?(parent)
      @deconstruct
    end

    def delegated?
      @delegated.length > 0
    end

    def delegate(*args)
			mapping = args.last.is_a?(Hash) ? args.pop : {}
      args.each{|arg|mapping[arg] = arg}
			mapping.each do |method, alias_method|
				@model.def_lazy_delegator method, alias_method, &@construct
			end
			@delegated.merge!(mapping)
    end

		#Instantiates the nested model only when absolutely necessary
		def delegate_property(*args)
			mapping = args.last.is_a?(Hash) ? args.pop : {}
      args.each{|arg|mapping[arg] = arg}
			mapping.each do |method, alias_method|
				@model.def_property_delegator self.association_id, method, alias_method
				@model.def_property_delegator self.association_id, "#{method}=", "#{alias_method}="
			end
			@delegated.merge!(mapping)
		end
  end


  def mimic(accessor, options = {}, &block)
    self.class_eval{include Attributes}
    @mimics ||= {}
    @mimics[accessor] = Base.new(self, accessor, options, &block)
  end

  def mimics
    @mimics
  end

  def has_one(association_id, options = {}, &block)
		mimic = {:mimic => options.delete(:mimic)}
    super
		nested_record association_id, options.merge(mimic), &block
  end

  def belongs_to(association_id, options = {}, &block)
		mimic = {:mimic => options.delete(:mimic)}
    super
		nested_record association_id, options.merge(mimic), &block
  end

private

	def nested_record(association_id, options = {}, &block)
		if block_given?
			self.mimic(association_id, options.merge(:extend => NestedRecord), &block)
		elsif options[:mimic]
			self.mimic(association_id, options.merge(:extend => NestedRecord))
		end
	end
end

Mimic::Base.logger = Rails.logger rescue Logger.new(STDOUT)
ActiveRecord::Base.class_eval{extend Mimic}
ActiveRecord::Reflection::AssociationReflection.class_eval do
  def related_model
  	polymorphic = self.options[:polymorphic]
  	if polymorphic
	  	model = self.active_record
	  else
	    model_name = self.options[:class_name] || self.name.to_s.camelize.singularize
  	  model = model_name.constantize
  	end
  	model
  end
end

