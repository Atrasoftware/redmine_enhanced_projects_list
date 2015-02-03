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

        def self.project_tree_with_order(projects, order_desc, is_closed = false, &block)
          ancestors = []
          projects = get_all_projects(projects, order_desc, is_closed)
          projects.each do |project|
            while ancestors.any? && !project.is_descendant_of?(ancestors.last)
              ancestors.pop
            end
            yield project, ancestors.size
            ancestors << project
          end
        end

        def self.get_all_projects(projects, order_desc = false, is_closed = false)
          p=[]
           scope = Project.visible
          unless is_closed
            scope = scope.active
          end
          if order_desc
            prs = projects.sort_by{|p| [p.identifier] }.reverse
          else
              prs = projects.sort_by{|p| [p.identifier] }
          end
          sorting_projects(p, prs, scope)
        end

        def self.all_visible_projects(projects, scope, order_desc, p = [])
          projects.each do |project|
            p<< project
            scope = scope.where(parent_id: project.id)
            order_desc ? prs = scope.order("identifier DESC"): prs = scope.order("identifier")
            all_visible_projects(prs, scope, order_desc, p) if prs.present?
          end
          p
        end

        def self.sorting_projects(p, projects, scope)
          map_id = p.map(&:id)
          projects.each do |project|
            if project.parent_id.nil?
              p<< project
            elsif map_id.include?(project.parent_id) and !map_id.include?(project.id)
              p<< project
            elsif !scope.map(&:id).include?(project.parent_id)
              p<< project
            end
            prs = scope.where(parent_id: project.id)
            sorting_projects(p, prs, scope) if prs.present?
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
      project_tree_with_order(projects, order_desc, false, &block)
    end
  end

  module InstanceMethods

  end

end