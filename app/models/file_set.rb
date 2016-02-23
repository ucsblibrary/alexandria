class FileSet < ActiveFedora::Base
  include ::CurationConcerns::FileSetBehavior
  include WithAdminPolicy

  directly_contains_one :restored, through: :files, type: ::RDF::URI('http://pcdm.org/use#IntermediateFile'), class_name: 'Hydra::PCDM::File'

  # Override of CurationConcerns. Since we have admin_policy rather than users with edit permission
  def paranoid_permissions
    true
  end

  def self.indexer
    FileSetIndexer
  end
end
