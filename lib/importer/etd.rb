module Importer
  class ETD

    # Attributes for the ETD collection
    COLLECTION_ATTRIBUTES = { accession_number: ['etds'] }
    attr_reader :collection

    def initialize
      @collection = Importer::Factory::CollectionFactory.new(COLLECTION_ATTRIBUTES).find
    end

    def run
      abort_import unless @collection
    end

    private

      def abort_import
        puts
        puts "ABORTING IMPORT:  Before you can import ETD records, the ETD collection must exist.  Please import the ETD collection record first, then re-try this import."
        puts

        raise CollectionNotFound.new("Not Found: Collection with accession number #{COLLECTION_ATTRIBUTES[:accession_number]}")
      end

  end
end
