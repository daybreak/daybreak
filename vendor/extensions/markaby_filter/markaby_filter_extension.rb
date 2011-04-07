class MarkabyFilterExtension < Radiant::Extension
  version "1.0"
  description "Allows you to compose page parts or snippets using Markaby."
  url "http://en.wikipedia.org/wiki/Markaby"

  def activate
    MarkabyFilter
  end
end

