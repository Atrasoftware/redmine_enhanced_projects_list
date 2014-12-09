require_dependency 'project'

module  Patches
  module ProjectPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do

        def self.project_tree_with_order(projects, order_desc)
          ancestors = []
          p=[]
          scope = Project
          if order_desc
            prs = projects.select{|pr| pr.parent_id.nil?}.sort_by(&:identifier).reverse
          else
            prs = projects.select{|pr| pr.parent_id.nil?}.sort_by(&:identifier)
          end

          projects = sorting_projects(p,prs,scope,order_desc)

          projects.each do |project|
            while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
              ancestors.pop
            end
            yield project, ancestors.size
            ancestors << project
          end
        end
        def self.sorting_projects(p,projects,all_projects,order_desc)
          projects.each do |project|
            p<< project
            if order_desc
            prs = all_projects.select{|pr| pr.parent_id== project.id}.sort_by(&:identifier).reverse
            else
              prs = all_projects.select{|pr| pr.parent_id== project.id}.sort_by(&:identifier)
              end
            if prs.present?
              sorting_projects(p,prs,all_projects,order_desc)
            end
          end
          p
        end

      end
    end

      end
  module ClassMethods
  end

  module InstanceMethods

  end

      end