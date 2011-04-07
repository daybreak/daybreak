class RelationsExtension < Radiant::Extension
  def activate
    Page.class_eval do
      has_many :superior_relations, :class_name => 'Relation', :as => :superior
      has_many :subordinate_relations, :class_name => 'Relation', :as => :subordinate

      def appear_on_ids
        self.subordinate_relations.map{|relation|relation.superior.id}
      end

      def appear_on_ids=(proposed_ids)
        proposed_ids = proposed_ids.map{|id|id.to_i}
        existing_ids = self.appear_on_ids
        removed_ids = existing_ids - proposed_ids
        added_ids = proposed_ids - existing_ids
        self.subordinate_relations.select{|relation|removed_ids.include? relation.superior.id}.each{|relation|relation.destroy}
        added_ids.each do |id|
          rel = self.subordinate_relations.build(:superior => Page.find(id), :relation => 'appears on')
        end
      end
    end
  end
end

