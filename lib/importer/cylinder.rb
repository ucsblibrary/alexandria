require File.expand_path('../factory/collection_factory', __FILE__)

module Importer
  class Cylinder

    # Array of MARC record files to import.
    attr_reader :metadata_files

    # The directory that contains the binary (audio) files to attach to the cylinder records.
    attr_reader :files_dir

    # The command line options that were passed in
    attr_reader :options

    # Keep track of how many cylinder records we have imported.
    attr_reader :imported_records

    # The cylinders collection
    attr_reader :collection

    # Attributes for cylinders collection
    COLLECTION_ATTRIBUTES = {
      id: 'cylinders',
      identifier: ['cylinders'],
      title: ['Wax Cylinders'],
      accession_number: ['Cylinders'],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID }


    def initialize(metadata_files, files_dir, options={})
      @metadata_files = metadata_files
      @files_dir = files_dir
      @options = options
      @imported_records = []
      @collection = Importer::Factory::CollectionFactory.new(COLLECTION_ATTRIBUTES).find_or_create

      $stdout.sync = true  # flush output immediately
    end

    def run
      # XMLReader's Enumerable methods are destructive, so move the
      # MARC::Records to an array so we can measure them:
      # https://github.com/ruby-marc/ruby-marc/pull/47
      marcs = metadata_files.map do |m|
        MARC::XMLReader.new(m).map { |o| o }
      end.flatten

      cylinders = marcs.length

      if options[:skip] && options[:skip] >= cylinders
        raise ArgumentError, "Number of records skipped (#{options[:skip]}) greater than total records to ingest"
      end

      # https://github.com/traject/traject/blob/master/lib/traject/indexer.rb#L101
      indexer = Traject::Indexer.new
      indexer.load_config_file('lib/traject/audio_config.rb')
      indexer.settings(files_dir: files_dir)
      indexer.settings(verbose: options[:verbose])

      marcs.each_with_index do |record, count|
        next if options[:skip] && options[:skip] > count
        next if options[:number] && options[:number] <= imported_records_count

        if record['024'].blank? || record['024']['a'].blank?
          puts "Skipping record #{count + 1}: No ARK found"
          next
        end

        print_attributes(record, count + 1)

        start_record = Time.now
        rec = indexer.writer.put indexer.map_record(record)
        end_record = Time.now

        puts "Ingested record #{count + 1} of #{cylinders} "\
          "in #{end_record - start_record} seconds"

        @collection.members << rec
        @imported_records << rec
      end  # marcs.each_with_index
    ensure
      indexer.writer.close if indexer && indexer.writer
      save_collection!
      puts "Reindexing records"
      @imported_records.each do |rec|
        rec.update_index  # Index the collection label
      end
    end

    # For performance reasons, we save the collection at the
    # end of the import, instead of once for each cylinder.
    def save_collection!
      start_time = Time.now
      puts "#{start_time.strftime("%Y-%-m-%-d %H:%M:%S")} Saving cylinders collection (this may take some time)"
      @collection.save!
      stop_time = Time.now
      minutes = (stop_time - start_time) / 60.0
      printf "Collection saved in %0.1f minutes\n", minutes
    end

    def imported_records_count
      @imported_records.count
    end

    private

      def print_attributes(record, item_number)
        return unless options[:verbose]
        puts
        puts "Object attributes for item #{item_number}:"
        puts record.class
        puts record
        puts
      end

  end
end
