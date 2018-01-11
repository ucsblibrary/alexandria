# frozen_string_literal: true

require "proquest"

module Importer::ETD
  # Attributes for the ETD collection
  COLLECTION_ATTRIBUTES = { accession_number: ["etds"] }.freeze

  # @param [Array<String>] meta
  # @param [Array<String>] data
  # @param [Hash] options See the options specified with Trollop in {bin/ingest}
  # @param [Logger] logger
  # @return [Integer]
  def self.import(meta:, data:, options: {}, logger: Logger.new(STDOUT))
    raise ArgumentError, "Nothing found in #{data}" if data.empty?
    collection = ensure_collection_exists(logger: logger)
    ingests = 0

    etds = unpack(
      Parse.find_paths(data),
      options,
      Dir.mktmpdir
    )

    if etds.empty?
      raise ArgumentError,
            "Number of records skipped (#{options[:skip]}) "\
            "greater than total records to ingest"
    end

    begin
      ingests += ingest_batch(metadata: meta,
                              data: etds,
                              collection: collection.id,
                              options: options,
                              logger: logger)
    rescue IngestError => e
      raise IngestError, reached: (ingests + e.reached)
    end

    ingests
  end

  def self.unpack(data, options, destination)
    # Don't unzip ETDs we won't use
    data.drop(options[:skip]).map.with_index do |zip, i|
      next unless File.extname(zip) == ".zip"

      # i starts at zero, so use greater-than instead of >=
      if !options[:number] || options[:number] > i
        Proquest.extract(zip, "#{destination}/#{File.basename(zip)}")
      end
    end.compact
  end

  def self.extract_marc(meta:, data:, logger: Logger.new(STDOUT))
    if meta.empty?
      logger.info "No metadata provided; fetching from Pegasus"
      data.map { |e| e[:xml] }.map do |x|
        raise IngestError, "Bad zipfile source: #{e}" if x.nil?
        MARC::XMLReader.new(
          StringIO.new(
            Parse::ETD.parse_file(x)
          )
        ).map { |o| o }
      end
    else
      meta.map do |m|
        # Enumerable methods on XMLReaders are destructive,
        # so pull the individual records into a regular
        # Array; see
        # https://github.com/ruby-marc/ruby-marc/pull/47
        MARC::XMLReader.new(m).map { |o| o }.select do |record|
          # only keep records for which we've provided data
          data.any? { |etd| etd[:pdf].include? record["956"]["f"] }
        end
      end
    end.flatten
  end

  def self.ingest_batch(metadata:,
                        data:,
                        collection:,
                        options: {},
                        logger: Logger.new(STDOUT))
    ingests = 0
    extract_marc(meta: metadata,
                 data: data,
                 logger: logger).each_with_index do |record, count|
      break if options[:number] && options[:number] <= ingests

      files = data.select do |etd|
        etd[:pdf].include? record["956"]["f"]
      end.first

      begin
        ingest_etd(record: record,
                   data: files,
                   collection: collection,
                   logger: logger)
      rescue => e
        logger.error e.message
        logger.error e.backtrace
        raise IngestError, reached: ingests
      rescue Interrupt
        logger.error "\nIngest stopped, cleaning up..."
        raise IngestError, reached: ingests
      end

      ingests += 1

      # Since earlier we skipped the unzip operations we don't
      # need, the array of records to iterate over is smaller, so
      # we modify the numbers here so that we still get the
      # correct "Ingested X of out Y records" readout.
      logger.info "Queued record #{count + 1 + options[:skip]} "\
                  "of #{data.length + options[:skip]}."
    end

    ingests
  end

  def self.ingest_etd(record:,
                      data:,
                      collection:,
                      logger: Logger.new(STDOUT))
    # The 956$f MARC field holds the name of the PDF from
    # ProQuest; we need this field to match data with metadata
    if record["956"].nil? || record["956"]["f"].nil?
      logger.error record
      logger.error "MARC is missing 956$f field; cannot process this record"
      return
    end

    logger.debug "Object attributes:"
    logger.debug record
    logger.debug "Associated data for item:"
    logger.debug data

    indexer = Traject::Indexer.new
    indexer.load_config_file("lib/traject/etd_config.rb")

    indexer.settings(
      etd: data,
      local_collection_id: collection,
      logger: logger
    )

    indexer.writer.put indexer.map_record(record)
    indexer.writer.close
  end

  def self.ensure_collection_exists(logger: Logger.new(STDOUT))
    collection = Importer::Factory::CollectionFactory.new(
      COLLECTION_ATTRIBUTES,
      [],
      logger
    ).find

    return collection if collection.present?

    logger.error "ABORTING IMPORT:  Before you can import ETD records, "\
                 "the ETD collection must exist."
    logger.error "Please import the ETD collection record first, "\
                 "then re-try this import."

    raise CollectionNotFound,
          "Not Found: Collection with accession number " +
          COLLECTION_ATTRIBUTES[:accession_number].to_s
  end
end
