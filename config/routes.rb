# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get '/find_sub_project', :to=> "enhanced_projects#index"
get 'context_menus/project', :to => 'context_menus#project_context_menu', :as => 'project_context_menu'
get 'context_menus/update_project_cf', :to => 'context_menus#update_project_cf' , :as => 'update_project_cf'