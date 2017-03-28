# frozen_string_literal: true

module Importer::Factory
  class MapSetFactory < ObjectFactory
    # Note: A MapSet does not have any attached files
    include WithAssociatedCollection
    self.klass = MapSet
    self.system_identifier_field = :accession_number
  end
end
