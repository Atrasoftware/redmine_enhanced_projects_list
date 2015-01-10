require_dependency 'context_menus_controller'

module  Patches
  module ContextMenusControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        include ApplicationHelper
      end
    end
  end
  module ClassMethods
  end

  module InstanceMethods
    def project_context_menu
      ###
      # edit
      # close
      # copy
      # archive
      # #
      @projects = params[:ids]
      @project = Project.find(@projects.first)

      @can = {:edit => User.current.allowed_to?(:edit_project, @project),
              :update => User.current.allowed_to?(:edit_project, @project),
              :close => User.current.allowed_to?(:close_project, @project),
              :copy => User.current.allowed_to?(:copy_project, @project),
      }

      @cfs = @project.visible_custom_field_values.map{|cf| [cf.custom_field.name, format_object(cf, false).html_safe]}
      @cfs.reject!{|cf| cf[1].nil? or cf[1].blank? }
      render :layout => false
    end
  end
end