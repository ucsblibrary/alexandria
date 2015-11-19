class CollectionIndexer < ActiveFedora::IndexingService
  def rdf_service
    RDF::DeepIndexingService
  end
end
