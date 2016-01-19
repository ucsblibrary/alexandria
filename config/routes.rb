Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  root 'welcome#index'

  get 'welcome/about', as: 'about'

  post 'contact_us' => 'contact_us#create', as: :contact_us
  get 'contact_us' => 'contact_us#new', as: :contact_us_form

  mount Blacklight::Engine => '/'

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
concerns :range_searchable

  end

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  get 'lib/:id' => 'catalog#show', constraints: { id: /ark:\/\d{5}\/f\w{7,9}/ }

  resources :downloads, only: :show
  resources :embargoes, only: [:index, :destroy] do
    collection do
      patch :update
    end
  end

  resources :etds, only: [] do
    resource :access, only: [:edit, :update, :destroy], controller: 'access'
    concerns :exportable
  end
  resources :images, only: [] do
    resource :access, only: [:edit, :update, :destroy], controller: 'access'
    concerns :exportable
  end

  resources :local_authorities, only: :index

  devise_for :users
  mount Hydra::RoleManagement::Engine => '/'
  mount Riiif::Engine => '/images'
  mount Qa::Engine => '/qa'
  mount HydraEditor::Engine => '/'
  mount Hydra::Collections::Engine => '/'

  resources :records, only: :destroy do
    get 'new_merge', on: :member
    post 'merge', on: :member
  end
end
