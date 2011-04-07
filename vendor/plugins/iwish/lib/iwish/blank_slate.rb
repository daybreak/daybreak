unless Module.constants.include?('BlankSlate')
  if Module.constants.include?('BasicObject')
    class BlankSlate < BasicObject
    end
  else
    class BlankSlate
      def self.wipe
        instance_methods.reject { |m| m =~ /^__/ }.each { |m| undef_method m }
      end
      def initialize
        BlankSlate.wipe
      end
    end
  end
end

