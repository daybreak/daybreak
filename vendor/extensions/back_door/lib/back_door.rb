module BackDoor

  FLAG_ATTRIBUTE = :@backdoor_processed 

  def attr
    unless attributes.instance_variable_get FLAG_ATTRIBUTE
      attributes.each do |key,value|
        # *toDO* if we use "locals" instead of "globals" in "globals.page.instance_eval", in <r:children:each> "self" is different from outter scope, why?
        attributes[ key] = globals.page.instance_eval( value[ 1..-1]).to_s if value && value.length > 1 && value[ 0..0] == "#"
      end
      attributes.instance_variable_set FLAG_ATTRIBUTE, true
    end
    attributes
  end

end

#allow us to refer to the containing tag
module BackDoor
  module Radius
    module Context
      def outer_tag
        @tag_binding_stack[@tag_binding_stack.length - 2] rescue nil
      end

      alias parent_tag outer_tag
      
      def outer_attr
        outer_tag.attributes || {}
      end
      
      alias parent_attr outer_attr
    end
  end
end

