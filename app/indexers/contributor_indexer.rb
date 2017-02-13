# frozen_string_literal: true
# Selects a sortable (singular) creator and unions all the contributor
# subtypes together into a single solr field.
class ContributorIndexer
  ALL_CONTRIBUTORS_FACET = Solrizer.solr_name("all_contributors_label", :facetable)
  ALL_CONTRIBUTORS_LABEL = Solrizer.solr_name("all_contributors_label", :stored_searchable)

  SORTABLE_CREATOR = Solrizer.solr_name("creator_label", :sortable)
  CREATOR_MULTIPLE = Solrizer.solr_name("creator_label", :stored_searchable)

  attr_reader :object

  # @param [ActiveFedora::Base] object
  # NOTE the object should already have had deep indexing done on all the relators
  # so that relator.rdf_label will have been retrieved from the remote store if it
  # wasn't present in the Marmotta cache.
  def initialize(object)
    @object = object
  end

  # This modifies the solr_document that was passed in to add the sortable creator
  # and the union of all the contrib subtypes
  #
  # The solr_doc should already contain a key 'creator_label_tesim' (CREATOR_MULTIPLE)
  # if the object has a creator.
  def generate_solr_document(solr_doc)
    solr_doc[SORTABLE_CREATOR] = sortable_creator(solr_doc)
    solr_doc[ALL_CONTRIBUTORS_LABEL] = all_contributors_combined
    solr_doc[ALL_CONTRIBUTORS_FACET] = solr_doc[ALL_CONTRIBUTORS_LABEL]
    solr_doc
  end

  private

    # Create a creator field suitable for sorting on
    def sortable_creator(solr_doc)
      solr_doc.fetch(CREATOR_MULTIPLE).first if solr_doc.key? CREATOR_MULTIPLE
    end

    # @return [NilClass, Array] Union of all the MARC relators. If non exist, return nil
    # Returns the rdf label if it's a URI, otherwise the value itself.
    def all_contributors_combined
      Metadata::RELATIONS.keys.map do |field|
        next if object[field].empty?
        object[field].map do |val|
          val.respond_to?(:rdf_label) ? val.rdf_label.first : val
        end
      end.flatten.compact
    end
end
