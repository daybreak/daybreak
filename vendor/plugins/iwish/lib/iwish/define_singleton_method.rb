module Kernel
  def metaclass
    class << self; self; end
  end

  def define_singleton_method(method, *args, &block)
    metaclass.send(:define_method, method, *args, &block)
  end
end

