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
          @settings = Setting.send "plugin_redmine_enhanced_projects_list"
          order = 'identifier'
          if @settings[:sorting_projects_order] == 'true'
            order = 'identifier DESC'
          end
          scope = Project
          unless params[:closed]
            scope = scope.active
          end
          #change the limit HERE
          # PS: LIMIT are set for project root ( parent id = null)
          @limit  = per_page_option
          @projects_count  = scope.visible.where("parent_id is null").size
          @projects_pages = Redmine::Pagination::Paginator.new @projects_count, @limit, params['page']
          @offset ||=@projects_pages.offset
          @projects =  scope.visible.where("parent_id is null").order(order).offset(@offset).limit(@limit)
        }
        format.api  {
          @offset, @limit = api_offset_and_limit
          @project_count = Project.visible.count
          binding.pry
          @projects = Project.visible.offset(@offset).limit(@limit).order('identifier').all
          #@projects = Project.get_all_projects(Project.visible.all, order == 'identifier DESC')[@offset..@limit]
        }
        format.atom {
          projects = Project.visible.order('created_on DESC').limit(Setting.feeds_limit.to_i).all
          render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
        }
        format.pdf{
          scope = Project
          unless params[:closed]
            scope = scope.active
          end
          @settings = Setting.send "plugin_redmine_enhanced_projects_list"
          if params[:project_search]
            scope= scope.visible.where("name like ? or identifier like ? ","%#{params[:project_search]}%","%#{params[:project_search]}%")
            val = CustomValue.where(:customized_type=> 'Project').where("value like ?", "%#{params[:project_search]}%" )
            val.each do |pr|
              scope<< pr.customized unless scope.map(&:identifier).include? pr.customized.identifier
            end
          else
            order = 'identifier'
            if @settings[:sorting_projects_order] == 'true'
              order = 'identifier DESC'
            end
            @limit  = per_page_option
            @projects_count  = scope.visible.where("parent_id is null").size
            @projects_pages = Redmine::Pagination::Paginator.new @projects_count, @limit, params['page']
            @offset ||=@projects_pages.offset
            scope= scope.visible.where("parent_id is null").order(order).offset(@offset).limit(@limit)
          end
          @projects = scope
              settings= Array.new
          settings << l("field_identifier".to_sym)
          Project.column_names.select{|col| @settings[col.to_sym] and col!= "identifier" }.each do |column|
            settings<< l("field_#{column}".to_sym)
          end
          CustomField.where(:type=> "ProjectCustomField").order("name ASC").select{|col| @settings[col.name.to_sym] }.each do |cf|
            settings<< cf.name
          end
          order_desc = false
          if @settings[:sorting_projects_order] == 'true'
            order_desc = true
          end
          @settings= @settings.except(:sorting_projects_order)
        send_data(ProjectsHelper.to_pdf(@projects,@settings,settings,'FR',order_desc), :type => 'application/pdf', :filename => 'projects.pdf')
        }

        format.js{
          @settings = Setting.send "plugin_redmine_enhanced_projects_list"
          order = 'identifier'
          if @settings[:sorting_projects_order] == 'true'
            order = 'identifier DESC'
          end
          scope = Project
          unless params[:closed]
            scope = scope.active
          end
          if params[:project_search]
            scope= scope.visible.where("name like ? or identifier like ? ","%#{params[:project_search]}%","%#{params[:project_search]}%")
            val = CustomValue.where(:customized_type=> 'Project').where("value like ?", "%#{params[:project_search]}%" )
            val.each do |pr|
              scope<< pr.customized unless scope.map(&:identifier).include? pr.customized.identifier
            end
          end
          @projects = scope
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


