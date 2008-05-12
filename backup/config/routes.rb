ActionController::Routing::Routes.draw do |map|
  map.resources :chat_users, :member => {"update_name" => :any, "update_crew" => :any, "create_crew" => :any ,"get_caption" => :any, 'activity' => :any}
  map.resources :crews, :collection => {"get_change_crew_list" => :any, "get_list" => :any}, :member => {"update_where" => :any, "update_where2" => :any, "update_title" => :any}
  map.resource :chat_session
  map.resource :messages, :collection => {"get_new" => :any}
  map.resources :teams

  map.resource :session
  map.connect 'page/*path' ,:controller => "pages", :action => "show"
  map.connect ':team_id' ,:controller => "chat", :action => "show", :requirements => {:team_id => /[\d]+/}
  
  map.resources :pages
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "site"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
