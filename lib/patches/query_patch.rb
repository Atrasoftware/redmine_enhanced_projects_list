require_dependency 'query'
module  Patches
  module QueryPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :all_projects_values, :modif
      end
    end
  end




module ClassMethods
end

module InstanceMethods
  def all_projects_values_with_modif
    return @all_projects_values if @all_projects_values

    values = []
    @settings = Setting.send "plugin_redmine_enhanced_projects_list"
    if @settings[:sorting_projects_order] == 'true'
      order_desc = true
    else
      order_desc = false
    end
    Project.project_tree_with_order(all_projects,order_desc) do |p, level|
      prefix = (level > 0 ? ('--' * level + ' ') : '')
      values << ["#{prefix}[#{p.identifier}]#{p.name}", p.id.to_s]
    end
    @all_projects_values = values
  end
end

end