# Overrides the CollectionsController provided by hydra-collections
# it provides display and search within collections.
class CollectionsController < ApplicationController
  include CurationConcerns::CollectionsControllerBehavior
  # FIXME: remove once https://github.com/projecthydra-labs/curation_concerns/issues/616 is closed
  include CurationConcerns::ThemedLayoutController

  self.theme = 'alexandria'

  # FIXME: https://github.com/projecthydra/hydra-collections/issues/110
  skip_before_filter :authenticate_user!

  # Overridden to use our local search builder with Admin Policies for the show page
  def collection_search_builder_class
    CollectionSearchBuilder
  end

  # Overridden to use our local search builder with Admin Policies for the index page
  def collections_search_builder_class
    CollectionsSearchBuilder
  end

  def collection_member_search_builder_class
    CollectionMemberSearchBuilder
  end

  configure_blacklight do |config|
    # Fields for the Collection show page
    config.show_fields.delete(Solrizer.solr_name('description', :stored_searchable))
  end

  def edit
    raise NotImplementedError
  end
end
