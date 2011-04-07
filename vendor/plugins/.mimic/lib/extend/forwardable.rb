require 'forwardable'
require 'nullify_empty_strings'

module Forwardable
	def self.tell(target, what, method, alias_method)
		out = "#{what} #{method}"
		out << " => #{alias_method}" unless method.to_s == alias_method.to_s
		out << " on #{target}"
		logger = target.try(:logger) || Logger.new(STDOUT)
		#logger.debug out
	end

	#TODO: *methods if there is a hash can handle mappings -- e.g. :old_method => :new_method
	#LazyDelegators perform some preliminary action (often instantiating the accessor object if it does not already exists) before providing the accessor to which the method will be delegated.  Delegation happens at the last possible moment.
	module LazyDelegators
		#TRIVIA: a lazy delegator is sometimes known as a "manager"
		def def_lazy_delegator(method, alias_method = method, &block)
			Forwardable.tell(self, "lazy delegator", method, alias_method)
			@lazy_delegators ||= {}
			@lazy_delegators[method.to_s.to_sym] = block
			self.class_eval <<-HERE
				def #{alias_method}(*args)
					block = self.class.instance_variable_get('@lazy_delegators')[:#{method}]
					target = self.instance_exec(:#{method}, *args, &block)
					target ? target.send(:#{method}, *args) : nil
				end
			HERE
		end

		def def_lazy_delegators(*methods, &block)
			methods.each{|method| self.def_lazy_delegator method, &block}
		end
	end
	include LazyDelegators

	#TODO: test
	module PropertyDelegators
		def def_property_delegator(accessor, method, alias_method = method)
			Forwardable.tell(self, "property delegator", method, alias_method)
			setter = !(method.to_s =~ /=$/).nil?
			if setter
				#build association only if a value if provided
				self.class_eval <<-HERE
					def #{alias_method}(value)
						target = self.send(:#{accessor})
						value = ::NullifyEmptyStrings.nullify(value)
						target ||= self.send(:build_#{accessor}) unless value.nil?
						target.send(:#{method}, value) if target || value
					end
				HERE
			else #getter
				self.class_eval <<-HERE
					def #{alias_method}
						target = self.send(:#{accessor})
						target ? target.send(:#{method}) : nil
					end
				HERE
			end
		end
		def def_property_delegators(accessor, *methods)
			methods.each{|method| self.def_property_delegator accessor, method}
		end
	end
	include PropertyDelegators

	#TryDelegators call the method only if the accessor itself exists, and otherwise return nil.
	module TryDelegators
		def def_try_delegator(accessor, method, alias_method = method)
			Forwardable.tell(self, "try delegator", method, alias_method)
			self.class_eval <<-HERE
				def #{alias_method}(*args)
					target = self.instance_variable_get(:#{accessor})
					target ||= self.send(:#{accessor}, *args) if self.respond_to?(:#{accessor})
					target.respond_to?(:#{method}) ? target.send(:#{method}, *args) : nil
				end
			HERE
		end
		def def_try_delegators(accessor, *methods)
			methods.each{|method| self.def_try_delegator accessor, method}
		end
	end
	include TryDelegators
end

