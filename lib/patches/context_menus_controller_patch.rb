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
              :copy => User.current.allowed_to?({controller: :projects, action: :copy}, @project),
              :reopen => User.current.allowed_to?(:close_project, @project)
      }
      @cfs = @project.visible_custom_field_values

      render :layout => false
    end

    def update_project_cf

      @project = Project.find(params[:id])
      params_cf = params[:project][:custome_fields]
      cfx = CustomField.find(params_cf)
      cf = @project.custom_values.select{|cf| cf.custom_field == cfx}.first
      if cf
        cf.value = params[:project][:value]
        cf.save
      else
        cfs = @project.custom_values.inject({}){|acc, cf| acc[cf.custom_field_id] = cf.value; acc}
        @project.safe_attributes = {"custom_field_values"=> cfs.merge({cfx.id=> params[:project][:value]})}
        @project.save
      end

      flash[:notice] = l(:notice_successful_update)
      redirect_to :back
    end
  end
end