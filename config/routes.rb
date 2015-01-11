# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
match '/find_sub_project', :to=> "enhanced_projects#index"
match 'context_menus/project', :to => 'context_menus#project_context_menu', :as => 'project_context_menu', :via => [:get, :post]
match 'context_menus/update_project_cf', :to => 'context_menus#update_project_cf' , :as => 'update_project_cf', :via => [:get, :post]