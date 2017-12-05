# frozen_string_literal: true

class FileSet < ActiveFedora::Base
  include Hyrax::FileSetBehavior
  include WithAdminPolicy
  include EmbargoBehavior

  directly_contains_one(
    :restored,
    through: :files,
    type: ::RDF::URI("http://pcdm.org/use#IntermediateFile"),
    class_name: "Hydra::PCDM::File"
  )

  # Override of Hyrax. Since we have admin_policy rather
  # than users with edit permission
  def paranoid_permissions
    true
  end

  def self.indexer
    FileSetIndexer
  end
end
