class GenericFile < ActiveFedora::Base
  contains :original

  def self.indexer
    GenericFileIndexer
  end

end
