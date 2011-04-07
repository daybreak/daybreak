class Array
	def to_h
		ary = self.collect do |value|
			display_as = yield(value)
			[value, display_as]
		end
		Hash[*ary.flatten]
	end
end

