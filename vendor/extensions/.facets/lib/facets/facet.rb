require 'active_record'
require 'mimic'
require 'facets/structure'

module Facets
  module ClassMethods
    def facet(association_id = nil, &block)
      association_id ||= "#{self.to_s.underscore}_facet"

      @facets ||= Collection.new

      class << self; attr_reader :facets end

      name = association_id.to_s.camelize

      begin
        name.constantize #Does it already exist? The developer may or may not have chosen to define it.
      rescue NameError => ex
        self.class_eval <<-HERE
          class ::#{name} < ActiveRecord::Base
            belongs_to :page
            before_update{|record|record.page.updated_at = Time.now} #simulate touch
          end
        HERE
        logger.info "Defined page facet: #{name}"
      end

      f = Facet.new(name.constantize, @facets)
      f.instance_eval(&block) if block_given?

      #TODO: determine input type based on field datatype -- use outfielder?
      f.model.columns.each{|column| f.fields{add column.name, :column => column}} unless f.fields.detect{|field| field.status == :use}

      f.fields do
        remove :page_id
        remove :created_at
        remove :updated_at
      end

      f.fields.select{|field| self.respond_to?(field.name)}.each{|field| field.status = :omit}

      delegates = {}
      f.fields.select{|field| field.status == :use}.map{|field| [field.name.to_s, field.as.to_s]}.each do |attribute, as|
        delegates[attribute.to_sym] = as.to_sym
        unless attribute.to_s[-1..-1] == '?'
          delegates["#{attribute}=".to_sym] = "#{as}=".to_sym
        end
      end

      self.has_one association_id, :foreign_key => :page_id, :autosave => true do
        delegate delegates
      end

      #allow for additional mimic settings to be specified
      self.mimics[association_id].instance_eval(&f.mimic)

      self.validates_associated association_id
      @facets << f
      f
    rescue Exception => ex
      logger.error "Facets error: #{ex.inspect}"
    end
  end
end

ActiveRecord::Base.class_eval{extend Facets::ClassMethods}

