class Opportunity < Page
=begin
  include Remarkable

  facet do
    model do
      validates_numericality_of :minimum_age
    end

    fields do
      section :meta do
        group :basic, :state => :collapsed do
          add :require_authentication, :input => :checkbox, :description => "When checked prevents the registration of anonymous users"
          add :minimum_age, :default => 21 #TODO: this won't be supplied unless the page is created as an Opportunity, not changed to one.  Allow interface to create page as an Opportunity.
        end
      end
    end

    parts do
      add :description
      remove :extended
    end
  end
=end
end

