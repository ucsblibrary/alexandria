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

    metadata = meta.map do |m|
      # TODO: this currently assumes one record per metadata file?
      parser = Parse::MODS.new(m, logger)
      {
        model: parser.model.to_s,
        attributes: parser.attributes,
      }
    end

    if options[:accession_numbers].present?
      metadata.select! do |record|
        options[:accession_numbers].include?(
          record[:attributes][:accession_number].first
        )
      end
    end

    metadata.drop(options[:skip]).each do |record|
      next if options[:number] && options[:number] <= ingests

      files = Parse.get_binary_paths(record[:attributes][:files], data)

      logger.debug "Object metadata:"
      logger.debug metadata
      logger.debug "Associated files:"
      files.each { |f| logger.debug f }

      IngestJob.perform_later(
        model: record[:model],
        attrs: record[:attributes].merge(
          admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID
        ).to_json,
        files: files
      )

      logger.info "Queued record #{ingests + 1} of #{metadata.length}"
      ingests += 1
    end

    ingests
  rescue StandardError => e
    logger.error e
    logger.error e.backtrace
    raise IngestError, reached: ingests
  rescue Interrupt
    logger.error "\nIngest stopped, cleaning up..."
    raise IngestError, reached: ingests
  end
end
