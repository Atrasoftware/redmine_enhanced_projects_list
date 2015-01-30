require_dependency 'issues_helper'

module  Patches
  module IssuesHelperPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :issue_list, :order

        def get_issue_tree(tree, issue, issues, &block)
          tree<< issue if !tree.include? issue and issues.include? issue
          children = issue.children
          children.each do |child|
            tree = get_issue_tree(tree, child, issues, &block)
          end
          tree
        end
      end

      end

  end

  module ClassMethods
  end

  module InstanceMethods
    def issue_list_with_order(issues, &block)


      #issue_list_without_order(issues, &block)
=begin
    tree= []
   #   tree = issues.sort_by(&:lft)
      issues.each do |issue|

        tree = get_issue_tree(tree, issue, issues, &block)
      end

      issues = tree
=end
      if params[:group_by] == "project" or (!@query.nil? and @query.group_by == "project" )
        projects = issues.map(&:project).uniq
        new_issues = Array.new
        Project.project_tree(projects) do |project, level|
          new_issues<< issues.select{|issue| issue.project == project}
        end
        issues =  new_issues.flatten
      end
      issue_list_without_order(issues, &block)

    end # end method issue list

  end

end