module Importer
  class CSVImporter
    def initialize(model, files_directory, metadata_file)
      AdminPolicy.ensure_admin_policy_exists
      @model = model
      @files_directory = files_directory
      @metadata_file = metadata_file
    end

    def import_all
      parser = CSVParser.new(@metadata_file)
      count = 0
      parser.each do |attributes|
        create_fedora_objects(attributes.merge(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID))
        # TODO: need to get the file to import too.
        count += 1
      end
      count
    end

    private

      # Build a factory to create the objects in fedora.
      def create_fedora_objects(attributes)
        Factory.for(@model.to_s).new(attributes, @files_directory).run
      end
  end
end
