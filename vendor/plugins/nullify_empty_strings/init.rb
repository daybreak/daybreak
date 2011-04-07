require 'nullify_empty_strings'
require 'active_record'

ActiveRecord::Base.class_eval{include NullifyEmptyStrings}

#TODO: could a rack app handle this just as well?
