require_dependency 'project'

module  Patches
  module ProjectPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do

        class<< self
          alias_method_chain :project_tree, :new_order
        end

        def self.project_tree_with_order(projects, order_desc, &block)

          ancestors = []
         projects = get_all_projects(projects,order_desc)
          projects.each do |project|
            while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
              ancestors.pop
            end
            yield project, ancestors.size
            ancestors << project
          end

        end

        def self.get_all_projects(projects,order_desc=false)
          p=[]
          scope = Project
          if order_desc
            prs = projects.sort_by(&:identifier).reverse
          else
            prs = projects.sort_by(&:identifier)
          end
          sorting_projects(p,prs,scope,order_desc)
        end

        def self.sorting_projects(p,projects,all_projects,order_desc)
          projects.each do |project|
            p<< project
            if order_desc
              prs = all_projects.select{|pr| pr.parent_id== project.id}.sort_by(&:identifier).reverse
            else
              prs = all_projects.select{|pr| pr.parent_id== project.id}.sort_by(&:identifier)
            end
            sorting_projects(p, prs, all_projects, order_desc) if prs.present?
          end
          p
        end

      end
    end

      end
  module ClassMethods
   def project_tree_with_new_order(projects, &block)
     settings = Setting.send "plugin_redmine_enhanced_projects_list"
     if settings[:sorting_projects_order] == 'true'
       order_desc = true
     else
       order_desc = false
     end
    project_tree_with_order(projects, order_desc, &block)
    end
  end

  module InstanceMethods

  end

      end