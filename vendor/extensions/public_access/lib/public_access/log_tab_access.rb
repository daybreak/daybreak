#puts "Will now display Radiant Tab access..."
module Radiant
  class AdminUI
    class Tab
      def shown_for?(user)
      	#puts "#{self.name.ljust(8)}|#{self.url.ljust(20)}|#{visibility.inspect}"
        visibility.include?(:all) or visibility.any? { |role| user.send("#{role}?") }
      end  
    end
  end
end
