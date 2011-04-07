require 'active_record'

#Forwardable pattern for an ActiveRecord model.
module Doppleganger
  module ClassMethods
    def has_one(association_id, options = {})
      result = super
      dopplegangs association_id, doppleganger_options if doppleganger_options = options.delete(:dopplegangs)
      result
    end

    def belongs_to(association_id, options = {})
      result = super
      dopplegangs association_id, doppleganger_options if doppleganger_options = options.delete(:dopplegangs)
      result
    end

    def dopplegangs(association_id, options = {})
      #TODO: port to mimic -- delete doppleganger
      self.class_eval do
        @proxied_properties ||= Set.new
        class << self; attr_accessor :proxied_properties end

        def extended_attributes
          attributes.merge(proxied_attributes)
        end

        def proxied_attributes
          props = {}
          [*self.class.proxied_properties].each{|prop| props[prop.to_s] = self.send(prop)}
          props
        end
      end
      one_to_one = self.reflect_on_association(association_id).macro == :has_one
      properties = options[:attributes] || []
      properties = Hash[*properties.collect { |property| [property.to_s, property.to_s]}.flatten] if properties.kind_of? Array
      properties.each_pair do |property, proxy_as|
        logger.info "Doppleganging #{association_id}.#{property}" + (property == proxy_as ? "" : " as #{proxy_as}") + " on #{self}."
        if one_to_one
          ensure_assoc = <<-HERE
            if !value.nil? && !self.#{association_id}
              logger.info 'Doppleganged via association #{association_id}'
              self.build_#{association_id}
              fk_name = self.build_#{association_id}.class.reflect_on_all_associations.select{|assoc| self.is_a?(assoc.class_name.constantize)}.first.name.to_s
              self.build_#{association_id}.send(fk_name + '=', self) #establish both sides of the relationship
            end
          HERE
        else
          ensure_assoc = <<-HERE
            if !value.nil? && !self.#{association_id}
              logger.info 'Doppleganged via association #{association_id}'
              self.#{association_id}.build
            end
          HERE
        end

        #TODO: may not need a proxy for getter/setter
        code = ''

        begin
          unless property.to_s[-1..-1] == '?'
            code = <<-HERE
              def #{proxy_as}=(value)
                value = ::NullifyEmptyStrings.nullify(value)
                #{ensure_assoc}
                self.#{association_id}.#{property} = value if self.#{association_id} || value
              end
            HERE
            class_eval code
          end

          code = <<-HERE
            def #{proxy_as}
              associated = self.#{association_id}
              associated ? associated.#{property} : nil
            end
          HERE
          class_eval code

        rescue Exception => ex
          logger.error "Doppleganger compile error"
          logger.error ex.inspect
          logger.error '-'*100
          logger.error code
          logger.error '-'*100
        end
        @proxied_properties << proxy_as
      end

      methods = options[:methods] || []
      methods = Hash[*methods.collect { |method| [method.to_s, method.to_s]}.flatten] if methods.kind_of? Array
      methods.each_pair do |method, proxy_as|
        logger.info "Doppleganging #{association_id}.#{method} method" + (method == proxy_as ? "" : " as #{proxy_as}") + " on #{self}."
        class_eval <<-HERE
          def #{proxy_as}(*args, &block)
            associated = self.#{association_id}
            associated.#{method}(*args, &block)
          end
        HERE
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend Doppleganger::ClassMethods
end

