# frozen_string_literal: true

module Importer::Factory
  class CollectionFactory < ObjectFactory
    self.klass = Collection
    self.system_identifier_field = :accession_number

    def find
      klass.where(
        accession_number: attributes[:accession_number].first
      ).first
    end

    def find_or_create
      collection = find
      return collection if collection
      run(&:save!)
    end

    def attach_files(_object, _files); end
  end
end
