# frozen_string_literal: true

class Importer::Cylinder
  # Array of MARC record files to import.
  attr_reader :metadata_files

  # The directories that contains the binary (audio) files to attach
  # to the cylinder records.
  attr_reader :files_dirs

  # The command line options that were passed in
  attr_reader :options

  # Keep track of how many cylinder records we have imported.
  attr_reader :imported_records_count

  attr_reader :logger

  # Attributes for the cylinders collection
  COLLECTION_ATTRIBUTES = { accession_number: ["Cylinders"] }.freeze

  # @param [Array<String>] metadata_files
  # @param [Array<String>] files_dirs
  # @param [Hash] options See the options specified with Trollop in {bin/ingest}
  # @param [Logger] logger
  # @return [Collection]
  def initialize(meta:,
                 data:,
                 options: {},
                 logger: Logger.new(STDOUT))
    # flush output immediately
    $stdout.sync = true

    @files_dirs = Array(data)
    @imported_records_count = 0
    @logger = logger
    @metadata_files = meta
    @options = options

    @collection = Importer::Factory::CollectionFactory.new(
      COLLECTION_ATTRIBUTES, [], logger
    ).find
  end

  def indexer
    return @indexer if @indexer

    # https://github.com/traject/traject/blob/master/lib/traject/indexer.rb#L101
    @indexer = Traject::Indexer.new
    @indexer.load_config_file("lib/traject/audio_config.rb")
    @indexer.settings(local_collection_id: @collection.id) if @collection
    @indexer.settings(files_dirs: files_dirs, logger: logger)
    @indexer
  end

  def run
    abort_import unless @collection

    marcs = parse_marc_files(metadata_files)
    cylinders = marcs.length

    if options[:skip] && options[:skip] >= cylinders
      raise ArgumentError,
            "Number of records skipped (#{options[:skip]}) "\
            "greater than total records to ingest"
    end

    logger.debug "Audio files directories:"
    files_dirs.each { |d| logger.debug d }

    marcs.each_with_index do |record, count|
      next if options[:skip] && options[:skip] > count
      break if options[:number] && options[:number] <= imported_records_count

      if record["024"].blank? || record["024"]["a"].blank?
        logger.info "Skipping record #{count + 1}: No ARK found"
        next
      end

      logger.debug "Object attributes for item #{count + 1}:"
      logger.debug record.class
      logger.debug record

      start_record = Time.zone.now
      indexer.writer.put attributes(record, indexer)
      end_record = Time.zone.now

      @imported_records_count += 1

      logger.info "Ingested record #{count + 1} of #{cylinders} "\
                  "in #{end_record - start_record} seconds"
    end # marcs.each_with_index
  ensure
    indexer.writer.close if indexer && indexer.writer
    if @collection
      logger.info "Updating collection index"
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
      logger.error "ABORTING IMPORT:  Before you can import cylinder records, "\
                   "the cylinders collection must exist.  "\
                   "Please import the cylinders collection record first, "\
                   "then re-try this import."
      raise CollectionNotFound,
            "Not Found: Collection with accession number " +
            COLLECTION_ATTRIBUTES[:accession_number].to_s
    end
end
