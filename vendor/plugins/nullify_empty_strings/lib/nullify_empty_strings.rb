module NullifyEmptyStrings
	def self.included(base)
		base.class_eval do
			before_save :nullify_empty_strings
		end
	end

	def NullifyEmptyStrings.empty_string?(text)
		text.is_a?(String) && text.strip.length == 0
	end

	def self.nullify(text)
		NullifyEmptyStrings.empty_string?(text) ? nil : text
	end

	def nullify_empty_strings
		self.attributes.each do |key, value| 
		  self[key] = nil if NullifyEmptyStrings.empty_string?(value)
		end
	end
end
