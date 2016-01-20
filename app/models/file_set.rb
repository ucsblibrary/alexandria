class FileSet < ActiveFedora::Base
  include Hydra::Works::FileSetBehavior
  # include ::CurationConcerns::FileSetBehavior

  def self.indexer
    FileSetIndexer
  end
end
