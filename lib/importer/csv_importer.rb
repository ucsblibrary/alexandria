module Importer
  # Import a csv file with one work per row. The first row of the csv should be a
  # header row. The model for each row can either be specified in a column called
  # 'type' or globally by passing the model attribute
  class CSVImporter
    def initialize(metadata_file, files_directory, model = nil)
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
        model = attributes.delete(:type) || @model.to_s
        if model.empty?
          $stderr.puts 'ERROR: No model was specified'
          exit(1)
        end
        Factory.for(model).new(attributes, @files_directory).run
      end
  end
end
