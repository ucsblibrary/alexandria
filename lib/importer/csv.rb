# frozen_string_literal: true

require File.expand_path("../factory", __FILE__)

# Import objects from CSV metadata files
module Importer::CSV
  # @param [Array<String>] meta
  # @param [Array<String>] data
  # @param [Hash] options See the options specified with Trollop in {bin/ingest}
  # @param [Logger] log
  # @return [Integer] The number of records ingested
  def self.import(meta:, data:, options:, logger: Logger.new(STDOUT))
    logger.info "Starting ingest with options #{options.inspect}"

    ingested = 0

    meta.each do |m|
      table = ::CSV.table(m, encoding: "bom|UTF-8")

      if options[:skip] >= table.length
        raise ArgumentError,
              "Number of records skipped (#{options[:skip]}) "\
              "greater than total records to ingest"
      end

      logger.info "Ingesting file #{m}: #{table.length} records"

      begin
        ingested += ingest_sheet(meta: table,
                                 data: data,
                                 options: options,
                                 logger: logger)
      rescue IngestError => e
        raise IngestError, reached: (options[:skip] + ingested + e.reached)
      end
    end

    ingested
  end

  def self.ingest_sheet(meta:,
                        data: [],
                        options: { skip: 0 },
                        logger: Logger.new(STDOUT))
    ingested = 0

    rows_to_ingest = meta.drop(options[:skip])
    return 0 if rows_to_ingest.blank?

    collections = rows_to_ingest.select { |row| row[:type] == "Collection" }
    map_sets = rows_to_ingest.select { |row| row[:type] == "Map set" }
    index_maps = rows_to_ingest.select { |row| row[:type] == "Index map" }

    member_objects = rows_to_ingest.reject do |row|
      ["Collection", "Map set", "Index map"].include? row[:type]
    end

    [collections, map_sets, index_maps, member_objects].each do |set|
      # Don't send Collections or MapSets to the background, since
      # they need to complete before the objects they contain are
      # ingested; see
      # https://github.com/ucsblibrary/alexandria/pull/62#issuecomment-334261568
      bg = (set == member_objects)

      set.each_with_index do |row, i|
        next if options[:number] && options[:number] <= ingested

        begin
          ingest_row(
            background: bg,
            data: data,
            logger: logger,
            row: row
          )

          ingested += 1
        rescue Interrupt
          raise IngestError, reached: i
        rescue => e
          logger.error e.message
          logger.error e.backtrace
          raise IngestError, reached: i
        end
      end
    end

    ingested
  end

  def self.ingest_row(background: true,
                      row:,
                      data: [],
                      logger: Logger.new(STDOUT))
    # Check that all URIs are well formed
    row.fields.each { |field| ::Fields::URI.check_uri(field) }

    attrs = ::Parse::CSV.csv_attributes(row)

    if attrs[:accession_number].present?
      logger.info "Ingesting accession number #{attrs[:accession_number].first}"
    end

    files = Parse::CSV.get_binary_paths(attrs[:files], data)

    logger.debug "Object attributes:"
    attrs.each { |k, v| logger.debug "#{k}: #{v}" }
    logger.debug "Associated files:"
    files.each { |f| logger.debug f }

    attrs = ::Parse::CSV.strip_extra_spaces(attrs)
    attrs = ::Parse::CSV.handle_structural_metadata(attrs)
    attrs = ::Parse::CSV.transform_coordinates_to_dcmi_box(attrs)
    attrs = ::Parse::CSV.assign_access_policy(attrs)

    model = ::Parse::CSV.determine_model(attrs.delete(:type))
    raise NoModelError if model.blank?

    if background
      IngestJob.perform_later(model: model, attrs: attrs.to_json, files: files)
    else
      record = ::Importer::Factory.for(model).new(attrs, files, logger).run

      accession_string = if attrs[:accession_number].present?
                           " with accession number " +
                             attrs[:accession_number].first
                         end

      logger.info "#{model}#{accession_string} ingested as #{record.id}."
      record
    end
  end
end
