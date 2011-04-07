require 'markaby'
require 'pp'

class MarkabyFilter < TextFilter
  description_file File.dirname(__FILE__) + "/../markaby.html"
  def filter(render_text)
    output = nil
    begin
      output = Markaby::Builder.new(self.params){self.instance_eval(render_text)}
    rescue Exception => ex
      output = 'Error rendering content <!-- Markaby Filter -->'
      heading "Markaby Filter", '#', 100
      #heading(:params) { pp self.params }
      heading(:code)   { (render_text || "").split("\r\n").each{|line| puts line} }
      heading(:error)  { pp ex }
    end
    output
  end

  def heading(name, char = '-', width = 80)
    puts (char*width)
    puts (char*2) + ' ' + name.to_s
    puts (char*width)
    yield if block_given?
  end
end

