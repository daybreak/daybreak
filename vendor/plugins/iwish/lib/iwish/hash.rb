module IWish
  module Hash
  #{:this=>:that}.set(:foo, :bar).set(:the, :otherthing) #=> {:this=>:that, :foo=>:bar, :the=>:otherthing}
  #{:this=>:that}.set(:foo, nil).set(:the, :otherthing) #=> {:this=>:that, :the=>:otherthing}
  #{:this=>:that}.set(:foo => :bar).set(:the => :otherthing) #=> {:this=>:that, :foo=>:bar, :the=>:otherthing}
  #{:this=>:that}.set(:foo, :bar, :the, :otherthing) #=> {:this=>:that, :foo=>:bar, :the=>:otherthing}
  #{:this=>:that}.set(:foo => :bar, :the => :otherthing) #=> {:this=>:that, :foo=>:bar, :the=>:otherthing}
    def set(*args)
      hash = {}
      if args.length > 1
        args.each_slice(2) do |key, value|
          hash[key] = value
        end
      else
        hash = args[0] if args[0].is_a?(::Hash)
      end
      hash.each_pair do |key,value|
        self[key] = value if value
        self.delete(key) unless value
      end
      self
    end

    #creates a new hash having only the listed keys
    def only(*keys)
      h = {}
      keys.each{|key|h[key] = self[key]}
      h
    end

    def only!(*keys)
      self.replace(self.only(*keys))
    end

#Where is this already implemented?
=begin
    def map
      h = {}
      self.each_pair do |key,value|
        result = [*yield(key,value)]
        pp result
        if result.length == 1 #remapping value
          h[key] = result.first
        elsif result.length == 2 #remapping key and value
          h[result.first] = result.last
        else
          raise "Hash#map block cannot return more than two values"
        end
      end
      h
    end

    def map!(&block)
      self.replace(self.map(&block))
    end
=end

    def symbolize_keys
      self.map{|k,v|[k.to_s.to_sym,v]}
    end

    def symbolize_keys!
      self.replace(self.symbolize_keys)
    end

    def symbolize_values
      self.map{|k,v|[k,v.to_s.to_sym]}
    end

    def symbolize_values!
      self.replace(self.symbolize_values)
    end

    #creates a new hash having only the listed keys, removing those keys from the current
    def export(*keys)
      h = {}
      keys.each{|key|h[key] = self.delete(key)}
      h
    end

    alias unmerge export

    def implant(scope)
      self.each_pair{|key, value|scope.instance_variable_set("@#{key}", value)}
      self
    end

    def compact
      h = {}
      self.each_pair{|key,value| h[key] = value if value}
      h
    end

    def compact!
      self.replace(self.compact)
    end
  end
end

Hash.class_eval{include IWish::Hash}

