require_dependency 'issues_controller'

module  Patches
  module IssuesHelperPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :index, :order
      end
    end

  end

  module ClassMethods
  end

  module InstanceMethods
    def index_with_order
      retrieve_query
      sort_init(@query.sort_criteria.empty? ? [['parent', 'asc'], ['id', 'asc']] : @query.sort_criteria)
      sort_update(@query.sortable_columns)
      @query.sort_criteria = sort_criteria.to_a

      if @query.valid?
        case params[:format]
          when 'csv', 'pdf'
            @limit = Setting.issues_export_limit.to_i
            if params[:columns] == 'all'
              @query.column_names = @query.available_inline_columns.map(&:name)
            end
          when 'atom'
            @limit = Setting.feeds_limit.to_i
          when 'xml', 'json'
            @offset, @limit = api_offset_and_limit
            @query.column_names = %w(author)
          else
            @limit = per_page_option
        end

        @issue_count = @query.issue_count
        @issue_pages = Redmine::Pagination::Paginator.new @issue_count, @limit, params['page']
        @offset ||= @issue_pages.offset

        sort_issue = sort_clause
        if params[:group_by] == "project" or (!@query.nil? and @query.group_by == "project" )
          @settings = Setting.send "plugin_redmine_enhanced_projects_list"
          @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version], :order => sort_issue).sort_by{|issue| issue.project.identifier}
          if @settings[:sorting_projects_order] == 'true'
            @issues.reverse!
          end
          @issues = @issues[@offset..(@offset+@limit-1)]
        else
          @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                                  :order => sort_issue,
                                  :offset => @offset,
                                  :limit => @limit)
        end


        @issue_count_by_group = @query.issue_count_by_group

        respond_to do |format|
          format.html { render :template => 'issues/index', :layout => !request.xhr? }
          format.api  {
            Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
          }
          format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
          format.csv  { send_data(query_to_csv(@issues, @query, params), :type => 'text/csv; header=present', :filename => 'issues.csv') }
          format.pdf  { send_file_headers! :type => 'application/pdf', :filename => 'issues.pdf' }
        end
      else
        respond_to do |format|
          format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
          format.any(:atom, :csv, :pdf) { render(:nothing => true) }
          format.api { render_validation_errors(@query) }
        end
      end
    rescue ActiveRecord::RecordNotFound
      render_404

    end # end method issue list

  end

end
