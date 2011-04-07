module Kernel
  def my_methods
    (my_instance_methods + my_class_methods).sort
  end
  def my_instance_methods
    (methods - Object.methods).sort
  end
  def my_class_methods
    (self.class.methods - Object.methods).sort
  end
end

