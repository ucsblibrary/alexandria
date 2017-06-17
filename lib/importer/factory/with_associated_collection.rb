# frozen_string_literal: true

module Importer::Factory::WithAssociatedCollection
  extend ActiveSupport::Concern

  included do
    after_save :reindex_collection
  end

  def create_attributes
    attrs = super.except(:collection)
    attrs[:local_collection_id] = [collection.id] if collection?
    attrs
  end

  def update_attributes
    attrs = super.except(:collection)
    attrs[:local_collection_id] = [collection.id] if collection?
    attrs
  end

  def reindex_collection
    return unless collection?
    collection.update_index
  end

  private

    def collection?
      attributes.key?(:collection)
    end

    def collection
      collection_attrs = attributes.fetch(:collection).merge(
        admin_policy_id: attributes[:admin_policy_id]
      )

      ::Importer::Factory::CollectionFactory.new(
        collection_attrs
      ).find_or_create
    end
end
