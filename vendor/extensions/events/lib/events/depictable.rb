module Depictable
  def self.included(base)
    base.class_eval do
      include FileColumnHelper
      file_column :image, :magick => { :geometry => "900x700", :versions => { "form" => "300x300", "standard" => "400x593" } }
    end
  end
end

