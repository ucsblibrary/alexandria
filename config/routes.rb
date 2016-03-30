class AudioRoutingConcern
  def matches?(request)
    query = [
      ActiveFedora::SolrQueryBuilder.raw_query(ActiveFedora.id_field, request.params[:id]),
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: AudioRecording.to_class_uri)]
        .join(' AND '.freeze)
    results = ActiveFedora::SolrService.query query, fl: 'has_model_ssim'
    results.present?
  end
end

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

  get 'lib/:prot/:shoulder/:id' => 'curation_concerns/audio_recordings#show', constraints: AudioRoutingConcern.new
  get 'lib/:prot/:shoulder/:id' => 'catalog#show'

  resources :local_authorities, only: :index

  get 'authorities/agents/:id',        to: 'local_authorities#show', as: 'agent'
  get 'authorities/people/:id',        to: 'local_authorities#show', as: 'person'
  get 'authorities/groups/:id',        to: 'local_authorities#show', as: 'group'
  get 'authorities/organizations/:id', to: 'local_authorities#show', as: 'organization'
  get 'authorities/topics/:id',        to: 'local_authorities#show', as: 'topic'

  devise_for :users
  mount Hydra::RoleManagement::Engine => '/'
  mount Riiif::Engine => '/images'
  mount Qa::Engine => '/qa'
  mount HydraEditor::Engine => '/'
  mount Hydra::Collections::Engine => '/'

  mount CurationConcerns::Engine, at: '/'
  curation_concerns_collections
  curation_concerns_basic_routes do
    resource :access, only: [:edit, :update, :destroy], controller: 'access'
    concerns :exportable
  end
  curation_concerns_embargo_management

  resources :records, only: :destroy do
    get 'new_merge', on: :member
    post 'merge', on: :member
  end
end
