module Remarkable
  def self.included(base)
    base.facet :remark_facet do
      fields do
        section :footer do
          add :remarks, :input => :textarea
        end
      end
    end
  end
end

