Redmine::Plugin.register :redmine_enhanced_projects_list do
  name 'Redmine Enhanced Projects List plugin'
  author 'Bilel KEDIDI'
  description 'This is a plugin for Redmine'
  version '0.1.0'
  url 'https://github.com/Atrasoftware/redmine-enhanced-projects-list'

  permission :copy, :projects => :copy
  settings :default => {
      'name'  => true,
      'description'     => true,
      'created_on'         => true,
      'update_on' => true,
      'sorting_projects_order'=> false
  }, :partial => 'settings/setting'
end
Rails.application.config.to_prepare do
  ProjectsController.send(:include, Patches::ProjectsControllerPatch)
  ProjectsHelper.send(:include, Patches::ProjectsHelperPatch)
  Project.send(:include, Patches::ProjectPatch)
  IssuesController.send(:include, Patches::IssuesHelperPatch)
  IssueQuery.send(:include, Patches::IssueQueryPatch)
  QueriesHelper.send(:include, Patches::QueriesHelperPatch)
  ContextMenusController.send(:include, Patches::ContextMenusControllerPatch)
end