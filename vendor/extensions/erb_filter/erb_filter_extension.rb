class ErbFilterExtension < Radiant::Extension
  version "0.1"
  description "Allows you to compose page parts or snippets using ERB templates."
  url ""
  
  def activate
    ErbFilter
  end  
end
