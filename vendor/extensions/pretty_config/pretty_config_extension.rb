ActiveRecord::Base.class_eval{include NullifyEmptyStrings}

class PrettyConfigExtension < Radiant::Extension
  version "0.2"
  description "Syntactic sugar for defining/accessing config settings"
  url ""

  def activate
    Radiant::Config.send :extend, PrettyConfig
  end
end

