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
  module InstanceMethods
    def issue_list_with_order(issues, &block)
      projects = issues.map(&:project).uniq
      new_issues = Array.new
      Project.project_tree(projects) do |project, level|
        new_issues<< issues.select{|issue| issue.project == project}
      end
      issue_list_without_order(new_issues.flatten, &block)
    end
  end

end