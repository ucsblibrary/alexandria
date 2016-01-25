class FileSet < ActiveFedora::Base
  include ::CurationConcerns::FileSetBehavior

  # Override of CurationConcerns. Since we have admin_policy rather than users with edit permission
  def paranoid_permissions
    true
  end

  def self.indexer
    FileSetIndexer
  end
end
