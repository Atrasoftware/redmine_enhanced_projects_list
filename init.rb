Redmine::Plugin.register :redmine_enhanced_projects_list do
  name 'Redmine Enhanced Projects List plugin'
  author 'Bilel KEDIDI'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/bilel-kedidi/redmine_enhanced_projects_list'
  author_url 'https://github.com/bilel-kedidi'

  settings :default => {
      'name'  => true,
      'description'     => true,
      'created_on'         => true,
      'update_on' => true
  }, :partial => 'settings/setting'
end
Rails.application.config.to_prepare do
  ProjectsController.send(:include, Patches::ProjectsControllerPatch)

end