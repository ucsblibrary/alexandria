class CollectionIndexer < Hydra::PCDM::CollectionIndexer
  def rdf_service
    RDF::DeepIndexingService
  end
end
