module Contactable
  def self.requested?
    Proc.new {|facet| facet.page.requested?}
  end

  def self.included(base)
    base.facet :contact_facet do
      model do
	      validates_presence_of :contact_name,         :if => Contactable.requested?
	      validates_presence_of :contact_email,        :if => Contactable.requested?
	      validates_presence_of :contact_phone,        :if => Contactable.requested?
	      validates_presence_of :contact_full_address, :if => Contactable.requested?
      end

      fields do
        section :footer do
          group :contact, :state => :data do
            add :contact_name, :label => "Name", :classes => :stacked
            add :contact_email, :label => "Email", :classes => :stacked
            add :contact_phone, :label => "Phone", :classes => :stacked
            add :contact_full_address, :input => :textarea, :label => "Full Address"
          end
        end
      end
    end
    base.class_eval do
     	validates_associated :contact_facet
    end
  end
end

