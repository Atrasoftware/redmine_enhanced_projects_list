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

        def self.get_all_projects(projects, order_desc=false)
          p=[]
          scope = Project.visible
          if order_desc
            prs = projects.sort_by(&:identifier).reverse
          else
            prs = projects.sort_by(&:identifier)
          end
          sorting_projects(p, prs, scope, order_desc)
        end

        def self.sorting_projects(p, projects, scope, order_desc)
          projects.each do |project|
            if project.parent_id.nil? or (p.map(&:id).include?(project.parent_id) and !p.map(&:id).include?(project.id))
              p<< project  #!p.map(&:id).include?(project.id)  or !projects.map(&:id).include?(project.parent_id)
            else
              p<< project unless projects.map(&:id).include?(project.parent_id)
            end
            if order_desc
              prs = scope.select{|pr| pr.parent_id== project.id}.sort_by(&:identifier).reverse
            else
              prs = scope.select{|pr| pr.parent_id== project.id}.sort_by(&:identifier)
            end
            prs = prs.reject{|pr| p.map(&:id).include?(pr.id)}
            sorting_projects(p, prs, scope, order_desc) if prs.present?
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