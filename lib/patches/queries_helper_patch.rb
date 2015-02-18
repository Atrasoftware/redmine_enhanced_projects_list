require_dependency 'queries_helper'

module  Patches
  module QueriesHelperPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
       alias_method_chain :csv_content, :add

      end
    end
  end
  module ClassMethods

  end

  module InstanceMethods
    def csv_content_with_add(column, issue)
      begin
        value = column.value_object(issue)
      rescue
        cf = issue.project.visible_custom_field_values.select{|coll| coll.custom_field.name == column.caption }.first
        value = cf.nil? ? '' : cf.value
      end
      if value.is_a?(Array)
        value.collect {|v| csv_value(column, issue, v)}.compact.join(', ')
      else
        csv_value(column, issue, value)
      end
    end
  end
end