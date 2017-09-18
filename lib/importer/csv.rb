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

    meta.drop(options[:skip]).each_with_index do |row, i|
      next if options[:number] && options[:number] <= ingested

      begin
        logger.info "Ingesting record #{ingested + 1} "\
                    "of #{options[:number] || (meta.length - options[:skip])}"

        ingest_row(row: row,
                   data: data,
                   logger: logger)

        ingested += 1
      rescue Interrupt
        raise IngestError, reached: i
      rescue => e
        logger.error e.message
        raise IngestError, reached: i
      end
    end

    ingested
  end

  def self.ingest_row(row:,
                      data: [],
                      logger: Logger.new(STDOUT))
    # Check that all URIs are well formed
    row.fields.each { |field| ::Fields::URI.check_uri(field) }

    attrs = ::Parse::CSV.csv_attributes(row)

    if attrs[:accession_number].present?
      logger.info "Ingesting accession number #{attrs[:accession_number].first}"
    end

    files = if attrs[:files].nil?
              []
            else
              data.select do |d|
                attrs[:files].any? { |f| f.include? File.basename(d) }
              end
            end

    logger.debug "Object attributes:"
    attrs.each { |k, v| logger.debug "#{k}: #{v}" }
    logger.debug "Associated files:"
    files.each { |f| logger.debug f }

    start_time = Time.zone.now

    attrs = ::Parse::CSV.strip_extra_spaces(attrs)
    attrs = ::Parse::CSV.handle_structural_metadata(attrs)
    attrs = ::Parse::CSV.transform_coordinates_to_dcmi_box(attrs)
    attrs = ::Parse::CSV.assign_access_policy(attrs)

    model = ::Parse::CSV.determine_model(attrs.delete(:type))
    raise NoModelError if model.blank?

    record = ::Importer::Factory.for(model).new(attrs, files, logger).run

    end_time = Time.zone.now

    accession_string = if attrs[:accession_number].present?
                         " with accession number " +
                           attrs[:accession_number].first
                       end

    logger.info "#{model}#{accession_string} ingested as "\
                "#{record.id} in #{end_time - start_time} seconds"
    record
  end
end # End of module
