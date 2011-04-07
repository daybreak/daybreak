class Not
	def initialize(ref)
		@ref = ref
	end

	def method_missing(method, *args, &block)
		!@ref.send(method, *args, &block)
	end
end

#allows:
# target = nil
# target.nil? #=> true
# target.not.nil? #=> false

module Kernel
	def not
		Not.new(self)
	end
end

