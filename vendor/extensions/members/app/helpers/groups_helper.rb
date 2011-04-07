module GroupsHelper
  include Markaby::Rails::ActionControllerHelpers
	include MarkupHelpers::Toggles
	include MarkupHelpers::TabControl
	include MarkupHelpers::Radiant

  def total_members(groups)
    total = 0
    groups.each{ |group| total += group.group_members.count }
    total
  end
end

