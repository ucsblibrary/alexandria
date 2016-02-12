# TODO: Merge this with CurationConcerns
# Overrides the CollectionsController provided by hydra-collections
# it provides display and search within collections.
class CollectionsController < ApplicationController
  include Hydra::Catalog
  include Hydra::CollectionsControllerBehavior

  # TODO: Remove when we go to curation_concerns
  load_and_authorize_resource only: :show
  skip_before_filter :authenticate_user!

  def collections_search_builder_class
    CollectionSearchBuilder
  end

  def collection_member_search_builder_class
    CollectionMemberSearchBuilder
  end

  def show
    if params[:q].present?
      # A normal catalog search
      redirect_to search_catalog_path(q: params[:q])
    else
      super
      _, @document = fetch(@collection.id)
    end
  end

  configure_blacklight do |config|
    # Fields for the Collection show page
    config.show_fields.delete(Solrizer.solr_name('description', :stored_searchable))

    # Fields for the Collection index page
    # (Clear out fields that were added by the CatalogController)
    config.index_fields.clear
  end

  protected

    # Override Blacklight method so that you can search and
    # facet within the current collection.
    def search_action_url(options = {})
      clean_options = options.except(:only_path)
      case action_name
      when 'show'
        collections.collection_path(clean_options)
      when 'index'
        collections.collections_path(clean_options)
      else
        super(*args)
      end
    end

    # This method is used in CatalogController's config,
    # so it needs to be defined.
    def show_type?(_, _document)
      false
    end
end
