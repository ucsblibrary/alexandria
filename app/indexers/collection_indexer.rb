class CollectionIndexer < CurationConcerns::CollectionIndexer
  def rdf_service
    RDF::DeepIndexingService
  end
end
