# frozen_string_literal: true

module Importer::MODS
  # @param [Array<String>] meta
  # @param [Array<String>] data
  # @param [Hash] options See the options specified with Trollop in {bin/ingest}
  # @param [Logger] logger
  # @return [Integer]
  def self.import(meta:, data:, options:, logger: Logger.new(STDOUT))
    if options[:skip] >= meta.length
      raise ArgumentError,
            "Number of records skipped (#{options[:skip]}) "\
            "greater than total records to ingest"
    end
    ingests = 0

    # TODO: this currently assumes one record per metadata file
    meta.each do |metadatum|
      if options[:skip] > ingests
        ingests += 1
        next
      end
      next if options[:number] && options[:number] <= ingests

      start_record = Time.zone.now

      ingest_mod(
        metadata: metadatum,
        data: Parse.find_paths(data),
        logger: logger
      )

      end_record = Time.zone.now

      logger.info "Ingested record #{ingests + 1} of #{meta.length} "\
                  "in #{end_record - start_record} seconds"

      ingests += 1
    end

    ingests
  rescue => e
    logger.error e
    logger.error e.backtrace
    raise IngestError, reached: ingests
  rescue Interrupt
    logger.error "\nIngest stopped, cleaning up..."
    raise IngestError, reached: ingests
  end

  def self.ingest_mod(metadata:, data:, logger: Logger.new(STDOUT))
    selected_data = data.select do |f|
      # FIXME: find a more reliable test
      meta_base = File.basename(metadata, ".xml")
      data_base = File.basename(f, File.extname(f))
      data_base.include?(meta_base) || meta_base.include?(data_base)
    end

    logger.debug "Object metadata:"
    logger.debug metadata
    logger.debug "Associated files:"
    selected_data.each { |f| logger.debug f }

    parser = Parse::MODS.new(metadata, logger)

    attrs = parser.attributes.merge(
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID
    )

    IngestJob.perform_later(
      model: parser.model.to_s,
      attrs: attrs.to_json,
      files: selected_data
    )
  end
end
