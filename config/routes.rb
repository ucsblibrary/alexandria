# frozen_string_literal: true

def for_model?(request, model)
  query = [
    ("_query_:\"" +
     ActiveFedora::SolrQueryBuilder
       .construct_query_for_ids([request.params[:id]]) +
     "\""),

    ActiveFedora::SolrQueryBuilder.construct_query_for_rel(
      [[:has_model, model.to_rdf_representation]]
    ),
  ].join(" AND ")
  results = ActiveFedora::SolrService.query query, fl: "has_model_ssim"
  results.present?
end

class CollectionRoutingConcern
  def matches?(request)
    for_model?(request, Collection)
  end
end

Rails.application.routes.draw do
  mount Blacklight::Engine => "/"
  mount Hydra::RoleManagement::Engine => "/"
  mount HydraEditor::Engine => "/"
  mount Qa::Engine => "/qa"
  mount Riiif::Engine => "/image-service", as: "riiif"

  root "welcome#index"

  get "welcome/about", as: "about"
  get "welcome/collection-usage-guidelines", as: "collection-usage-guidelines"
  get "welcome/using", as: "using"

  post "contact_us" => "contact_us#create", as: :contact_us
  get "contact_us" => "contact_us#new", as: :contact_us_form

  # new_user_session_path is hardcoded everywhere in Blacklight
  get "sign_in", to: "sessions#new", as: :new_user_session
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"

  get "404", to: "error#not_found"
  get "422", to: "error#server_error"
  get "500", to: "error#server_error"

  get "lib/:prot/:shoulder/:id" => "collections#show",
      constraints: CollectionRoutingConcern.new

  get "lib/:prot/:shoulder/:id" => "catalog#show", as: "catalog_ark"

  resources :local_authorities, only: :index

  get "authorities/agents/:id",
      to: "local_authorities#show",
      as: "agent"

  get "authorities/people/:id",
      to: "local_authorities#show",
      as: "person"

  get "authorities/groups/:id",
      to: "local_authorities#show",
      as: "group"

  get "authorities/organizations/:id",
      to: "local_authorities#show",
      as: "organization"

  get "authorities/topics/:id",
      to: "local_authorities#show",
      as: "topic"

  get "access/:id/edit", to: "access#edit", as: :edit_access
  post "access/:id/update", to: "access#update"
  post "access/:id/destroy", to: "access#destroy"
  post "access/:id/deactivate", to: "access#deactivate"

  concern :oai_provider, BlacklightOaiProvider::Routes.new

  concern :searchable, Blacklight::Routes::Searchable.new
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  resource :catalog,
           only: [:index],
           as: "catalog",
           path: "/catalog",
           controller: "catalog" do
    concerns :oai_provider
    concerns :searchable
    concerns :range_searchable
  end

  # Make sure to define this concern before using it in
  # `curation_concerns_basic_routes' below
  concern :exportable, Blacklight::Routes::Exportable.new
  resources :solr_documents,
            only: [:show],
            path: "/catalog",
            controller: "catalog" do
    concerns :exportable
  end

  mount CurationConcerns::Engine, at: "/"
  curation_concerns_collections
  curation_concerns_basic_routes

  resources :embargoes, only: [:index, :edit, :destroy] do
    collection do
      patch :update
    end
  end

  resources :records, only: :destroy do
    get "new_merge", on: :member
    post "merge", on: :member
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete "clear"
    end
  end
end
