class CollectionsController < ApplicationController
  before_action :find_collection_by_treeifed_id, only: :show
  include Hydra::Catalog
  include Hydra::CollectionsControllerBehavior

  skip_before_filter :authenticate_user!

  def collections_search_builder_class
    CollectionSearchBuilder
  end

  def collection_member_search_builder_class
    CollectionSearchBuilder
  end

  def collection_member_search_logic
    super + [:add_access_controls_to_solr_params]
  end

  def show
    if params[:q].present?
      # A normal catalog search
      redirect_to catalog_index_path(q: params[:q])
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

  private

    # Don't mutate the params hash, because that will screw up the kaminari pagination links
    # cancan's load_resource method is skipped if the @collection is already loaded as happens here:
    def find_collection_by_treeifed_id
      id = Identifier.treeify(params[:id])
      return if id.nil?
      @collection = Collection.find(id)
    rescue ActiveFedora::ObjectNotFoundError => e
      logger.error "404 Error\n" \
        "CollectionsController: #{e} thrown while searching for #{params[:id]}\n" \
        "\t#{params.inspect}\n"
      @unknown_type = 'Collection'
      @unknown_id = params[:id]
      render 'errors/not_found', status: 404
      return false
    end
end
