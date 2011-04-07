module PrettyConfig
  def need(key, options = {})
    filter = options[:filter]
    self.create(:key => key, :value => options[:default]) unless self[key]
    self.filter key, options[:filter] if options[:filter]
  end

  def filter(key, filter = nil)
    @@filters ||= {}
    @@filters[key.to_s] = filter if filter
    @@filters[key.to_s]
  end

  def get(&block)
    info = OpenStruct.new
    self.to_hash.each_pair do |key, value|
      nodes = key.split('.')
      last = nodes.pop
      curr = info
      nodes.each do |node|
        curr = curr.send(node) || curr.send("#{node}=", OpenStruct.new)
      end
      filter = self.filter(key)
      curr.send "#{last}=", filter ? filter.call(value) : value
    end
    (block_given? ? info.instance_eval(&block) : info) rescue nil
  end
end

