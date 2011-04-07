module ImageBox
  module Helpers
    def markaby(&block)
      Markaby::Builder.new({}, self, &block).to_s
    end
    
		#TODO: provide options logic
		def image_box(object_name, method, options = {})
      include_stylesheet 'image_box'
			@@image_box_number ||= 0
			@@image_box_number += 1	
			id = "image-box-#{@@image_box_number}"
			image = to_value(object_name, method)
			hide = "display: none;"
			exists = File.exists?(image) if image
			show = []
			show << (exists ? 'image' : 'browse')
      markaby do
        div :id => id, :class => 'image-box' do
          div :id => "#{id}-browse", :style => hide do
            text file_column_field(object_name.to_s, method)
            if exists 
              a.toggle :href => '#', :id => "#{id}-cancel", :onclick => "Element.toggle('#{id}-browse'); Element.toggle('#{id}-image');" do
                text "Cancel"
              end
            end
          end
          if exists
            div :id => "#{id}-image", :style => hide do
              text link_to_lightbox_image(object_name, method)
              text " " 
              a.toggle :href => '#', :id => "#{id}-change", :onclick => "Element.toggle('#{id}-browse'); Element.toggle('#{id}-image');" do
                text "Change"
              end
            end
          end
        end
        script :type => 'text/javascript' do
          text "  $('#{id}-#{exists ? 'image' : 'browse'}').style.display = '';"
        end
      end
		end
  end
end

module ApplicationHelper
  include ImageBox::Helpers
end
