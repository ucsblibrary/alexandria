# frozen_string_literal: true

require "proquest"

module Importer::ETD
  # Attributes for the ETD collection
  COLLECTION_ATTRIBUTES = { accession_number: ["etds"] }.freeze

  def self.import(meta, data, options)
    raise ArgumentError, "Nothing found in #{data}" if data.empty?

    collection = ensure_collection_exists
    ingests = 0

    Dir.mktmpdir do |temp|
      etds = unpack(data, options, temp)

      if etds.empty?
        raise ArgumentError,
              "Number of records skipped (#{options[:skip]}) "\
              "greater than total records to ingest"
      end

      begin
        ingests += ingest_batch(metadata: meta,
                                data: etds,
                                collection: collection.id,
                                options: options)
      rescue IngestError => e
        raise IngestError, reached: (ingests + e.reached)
      ensure
        puts "Updating collection index"
        collection.update_index
      end
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

  def self.extract_marc(metadata, etds)
    if metadata.empty?
      puts "No metadata provided; fetching from Pegasus"
      etds.map { |e| e[:xml] }.map do |x|
        if x.nil?
          $stderr.puts "Bad zipfile source: #{e}"
          raise IngestError
        end
        MARC::XMLReader.new(
          StringIO.new(
            Importer::ETDParser.parse_file(x)
          )
        ).map { |o| o }
      end
    else
      metadata.map do |m|
        # Enumerable methods on XMLReaders are destructive,
        # so pull the individual records into a regular
        # Array; see
        # https://github.com/ruby-marc/ruby-marc/pull/47
        MARC::XMLReader.new(m).map { |o| o }
      end
    end.flatten
  end

  def self.ingest_batch(metadata:, data:, collection:, options: {})
    ingests = 0

    extract_marc(metadata, data).each_with_index do |record, count|
      break if options[:number] && options[:number] <= ingests

      files = data.select do |etd|
        etd[:pdf].include? record["956"]["f"]
      end.first

      start_record = Time.zone.now

      begin
        ingest_etd(record: record,
                   data: files,
                   collection: collection,
                   options: options)
      rescue => e
        $stderr.puts e.message
        $stderr.puts e.backtrace
        raise IngestError, reached: ingests
      rescue Interrupt
        $stderr.puts "\nIngest stopped, cleaning up..."
        raise IngestError, reached: ingests
      end

      end_record = Time.zone.now
      ingests += 1

      # Since earlier we skipped the unzip operations we don't
      # need, the array of records to iterate over is smaller, so
      # we modify the numbers here so that we still get the
      # correct "Ingested X of out Y records" readout.
      puts "Ingested record #{count + 1 + options[:skip]} "\
           "of #{data.length + options[:skip]} "\
           "in #{end_record - start_record} seconds"
    end

    ingests
  end

  def self.ingest_etd(record:, data:, collection:, options: {})
    # The 956$f MARC field holds the name of the PDF from
    # ProQuest; we need this field to match data with metadata
    if record["956"].nil? || record["956"]["f"].nil?
      $stderr.puts record
      $stderr.puts
      $stderr.puts "MARC is missing 956$f field; cannot process this record"
      return
    end

    if options[:verbose]
      puts
      puts "Object attributes:"
      puts record
      puts
      puts "Associated data for item:"
      puts data
    end

    indexer = Traject::Indexer.new
    indexer.load_config_file("lib/traject/etd_config.rb")

    indexer.settings(
      etd: data,
      local_collection_id: collection
    )

    indexer.writer.put indexer.map_record(record)
    indexer.writer.close
  end

  def self.ensure_collection_exists
    collection = Importer::Factory::CollectionFactory.new(
      COLLECTION_ATTRIBUTES
    ).find

    return collection if collection.present?

    puts "ABORTING IMPORT:  Before you can import ETD records, "\
         "the ETD collection must exist."

    puts "Please import the ETD collection record first, "\
         "then re-try this import."

    raise CollectionNotFound,
          "Not Found: Collection with accession number " +
          COLLECTION_ATTRIBUTES[:accession_number].to_s
  end
end
