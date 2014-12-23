require_dependency 'queries_helper'

module  Patches
  module QueriesHelperPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
          alias_method_chain :query_available_inline_columns_options, :add
        alias_method_chain :query_selected_inline_columns_options, :add
      end
    end
  end
      module ClassMethods
        def get_plugin_redmine_enhanced
          settings = Setting.send "plugin_redmine_enhanced_projects_list"
          CustomField.where(:type=> "ProjectCustomField").order("name ASC").select{|col| settings[col.name.to_sym] }.map(&:name)
        end
      end

      module InstanceMethods
        def query_available_inline_columns_options_with_add(query)
          queries = (query.available_inline_columns - query.columns).reject(&:frozen?).collect {|column| [column.caption, column.name]}
          sessions = session[:query][:column_names]
            cfs = QueriesHelper.get_plugin_redmine_enhanced
            cfs.each do |cf|
              sessions ? (queries<< [cf, cf] unless sessions.include?(cf.to_sym)) : queries<< [cf, cf]
            end
          queries
        end

        def query_selected_inline_columns_options_with_add(query)
          queries= (query.inline_columns & query.available_inline_columns).reject(&:frozen?).collect {|column| [column.caption, column.name]}
          sessions = session[:query][:column_names]
          if sessions
            cfs = QueriesHelper.get_plugin_redmine_enhanced
            cfs.each do |cf|
              queries<< [cf, cf] if sessions.include?(cf.to_sym)
            end
          end
          queries
        end

      end
    end