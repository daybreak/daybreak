require 'erb'

class ErbFilter < TextFilter
  description_file File.dirname(__FILE__) + "/../erb.html"
  def filter(text)
    html = ERB.new(text)
    html.result(binding)
  end
end
