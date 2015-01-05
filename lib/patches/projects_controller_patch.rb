require_dependency 'projects_controller'

module  Patches
  module ProjectsControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do

        before_filter :require_admin, :only => [ :archive, :unarchive, :destroy ]
        alias_method_chain  :index, :filter_project
        before_filter :copy_authorize, :only=>[:copy]
      end
    end
  end
  module ClassMethods
  end

  module InstanceMethods

    def index_with_filter_project
      respond_to do |format|
        format.html {
          scope = Project
          unless params[:closed]
            scope = scope.active
          end
          @projects = scope.visible.order('lft').all
        }
        format.api  {
          @offset, @limit = api_offset_and_limit
          @project_count = Project.visible.count
          @projects = Project.visible.offset(@offset).limit(@limit).order('lft').all
        }
        format.atom {
          projects = Project.visible.order('created_on DESC').limit(Setting.feeds_limit.to_i).all
          render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
        }
      end
    end

    private
    def copy_authorize
      project = Project.find(params[:id])
      unless User.current.member_of?(project) and User.current.allowed_to?({:controller => :projects, :action => :copy}, project, :global => false)
          require_admin
      end
    end
  end
end


