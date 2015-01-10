require_dependency 'issues_helper'

module  Patches
  module IssuesHelperPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :issue_list, :order
      end

      end

  end
  module ClassMethods
  end
  module InstanceMethods
    def issue_list_with_order(issues, &block)
      if params[:group_by] == "project"
        projects = issues.map(&:project).uniq
        new_issues = Array.new
        Project.project_tree(projects) do |project, level|
          new_issues<< issues.select{|issue| issue.project == project}
        end
        issues =  new_issues.flatten
      end
      issue_list_without_order(issues, &block)
    end
  end

end