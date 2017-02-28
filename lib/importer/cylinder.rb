# frozen_string_literal: true

class Importer::Cylinder
  # Array of MARC record files to import.
  attr_reader :metadata_files

  # The directories that contains the binary (audio) files to attach to the cylinder records.
  attr_reader :files_dirs

  # The command line options that were passed in
  attr_reader :options

  # Keep track of how many cylinder records we have imported.
  attr_reader :imported_records_count

  # Attributes for the cylinders collection
  COLLECTION_ATTRIBUTES = { accession_number: ["Cylinders"] }.freeze

  def initialize(metadata_files, files_dirs, options = {})
    $stdout.sync = true # flush output immediately
    @metadata_files = metadata_files
    @files_dirs = files_dirs
    @options = options
    @imported_records_count = 0
    @collection = Importer::Factory::CollectionFactory.new(COLLECTION_ATTRIBUTES).find
  end

  def indexer
    return @indexer if @indexer

    # https://github.com/traject/traject/blob/master/lib/traject/indexer.rb#L101
    @indexer = Traject::Indexer.new
    @indexer.load_config_file("lib/traject/audio_config.rb")
    @indexer.settings(files_dirs: files_dirs)
    @indexer.settings(verbose: options[:verbose])
    @indexer.settings(local_collection_id: @collection.id) if @collection
    @indexer
  end

  def run
    abort_import unless @collection

    marcs = parse_marc_files(metadata_files)
    cylinders = marcs.length

    if options[:skip] && options[:skip] >= cylinders
      raise ArgumentError, "Number of records skipped (#{options[:skip]}) greater than total records to ingest"
    end

    print_files_dirs

    marcs.each_with_index do |record, count|
      next if options[:skip] && options[:skip] > count
      break if options[:number] && options[:number] <= imported_records_count

      if record["024"].blank? || record["024"]["a"].blank?
        puts "Skipping record #{count + 1}: No ARK found"
        next
      end

      print_attributes(record, count + 1)

      start_record = Time.now
      indexer.writer.put attributes(record, indexer)
      end_record = Time.now

      @imported_records_count += 1

      puts "Ingested record #{count + 1} of #{cylinders} "\
           "in #{end_record - start_record} seconds"
    end # marcs.each_with_index
  ensure
    indexer.writer.close if indexer && indexer.writer
    if @collection
      puts "Updating collection index"
      @collection.update_index
    end
  end

  # XMLReader's Enumerable methods are destructive, so move the
  # MARC::Records to an array so we can measure them:
  # https://github.com/ruby-marc/ruby-marc/pull/47
  def parse_marc_files(metadata_files)
    metadata_files.map do |m|
      MARC::XMLReader.new(m).map { |o| o }
    end.flatten
  end

  # Attributes for 1 MARC record
  def attributes(record, indexer)
    indexer.map_record(record)
  end

  private

    def abort_import
      puts
      puts "ABORTING IMPORT:  Before you can import cylinder records, the cylinders collection must exist.  Please import the cylinders collection record first, then re-try this import."
      puts

      raise CollectionNotFound, "Not Found: Collection with accession number #{COLLECTION_ATTRIBUTES[:accession_number]}"
    end

    def print_attributes(record, item_number)
      return unless options[:verbose]
      puts
      puts "Object attributes for item #{item_number}:"
      puts record.class
      puts record
      puts
    end

    def print_files_dirs
      return unless options[:verbose]
      puts
      puts "Audio files directories:"
      files_dirs.each { |d| puts d }
      puts
    end
end
