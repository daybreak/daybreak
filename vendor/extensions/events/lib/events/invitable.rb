module Invitable
  def self.included(base)
    base.facet :invitation_facet do
      mimic{delegate 'image_url' => 'invitation_image_url', 'image_relative_path' => 'invitation_image_relative_path', 'image_absolute_path' => 'invitation_image_absolute_path', 'image_options' => 'invitation_image_options'}
      model do
        include FileColumnHelper
	      file_column :image, :magick => { :geometry => "400x600"}

				def image_url(options = nil)
					url_for_file_column(self, "image", options)
				end
      end
      
      fields do
        section :footer do
          group :invitation, :state => :data do
            add :message, :label => 'Message', :as => :invitation      , :input => :textarea
            add :color  , :label => 'Color'  , :as => :invitation_color, :classes => :stacked
            add :image  , :label => 'Image'  , :as => :invitation_image, :classes => :stacked, :input => :file
          end
        end
      end
    end
    
    base.class_eval do
	    def invitation_image_temp
		    invitation_facet.try(:image_temp)
	    end

	    def invitation_image_temp=(value)
		    value = NullifyEmptyStrings.nullify(value)
		    self.build_invitation_facet if value && !self.invitation_facet
		    self.invitation_facet.image_temp = value if self.invitation_facet
	    end
    end
  end
end

