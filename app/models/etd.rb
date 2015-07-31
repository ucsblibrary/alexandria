require 'active_fedora/aggregation'
class ETD < ActiveFedora::Base
  include Metadata
  include LocalAuthorityHashAccessor
  include Hydra::AccessControls::Embargoable

  property :system_number, predicate: ::RDF::Vocab::MODS.recordIdentifier do |index|
    index.as :symbol
  end

  property :isbn, predicate: ::RDF::Vocab::Identifiers.isbn do |index|
    index.as :symbol
  end

  property :degree_grantor, predicate: ::RDF::Vocab::MARCRelators.dgg do |index|
    index.as :symbol
  end

  property :keywords, predicate: ::RDF::DC11.subject do |index|
    index.as :stored_searchable
  end

  property :issued, predicate: ::RDF::DC.issued do |index|
    index.as :displayable
  end

  include NestedAttributes
  include Hydra::Collections::Collectible
  aggregates :generic_files, predicate: ::RDF::URI("http://pcdm.org/models#hasMember")

  contains :proquest

  def self.indexer
    ETDIndexer
  end

  def to_param
    Identifier.noidify(id)
  end

  # Overriding Embargoable to set admin_policy_id
  # Set the current visibility to match what is described in the embargo.
  def embargo_visibility!
    return unless embargo_release_date
    uri = under_embargo? ? embargo.visibility_during_embargo : embargo.visibility_after_embargo
    self.admin_policy_id = ActiveFedora::Base.uri_to_id(uri.id)
  end

  # Override method from hydra-access-controls
  def enforce_future_date_for_embargo?
    false
  end

end

