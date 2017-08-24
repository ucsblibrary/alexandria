# frozen_string_literal: true

require "find"

module Importer::CLI
  def self.find_paths(params, extension = nil)
    return [] if params.blank?

    params.map do |arg|
      next arg if File.file?(arg)

      next unless Dir.exist?(arg)

      Find.find(arg).map do |path|
        next if File.directory?(path)
        next if extension.present? && File.extname(path) != extension
        path
      end
    end.flatten.compact
  end

  def self.make_logger(output:, level: "INFO")
    logger = Logger.new(output)
    logger.level = begin
                     "Logger::#{level.upcase}".constantize
                   rescue NameError
                     logger.warn "#{level} isn't a valid log level. "\
                                 "Defaulting to INFO."
                     Logger::INFO
                   end

    ActiveSupport::Deprecation.behavior = lambda do |message, backtrace|
      logger.warn message
      logger.warn backtrace
    end

    # For deprecation warnings from gems
    $stderr.reopen(output, "a")

    logger
  end

  def self.run(options)
    logger = make_logger(output: options[:logfile], level: options[:verbosity])

    # For each argument passed to --metadata, if it's a file with the
    # correct extension, add it to the array, otherwise drill down and add
    # each file within to the array
    metadata_ext = options[:format] == "csv" ? ".csv" : ".xml"
    meta = find_paths(options[:metadata], metadata_ext)

    data = if options[:format] == "cyl"
             # Just pass the options through, the {ObjectFactoryWriter}
             # currently does the path processing
             options[:data]
           else
             find_paths(options[:data])
           end

    logger.warn "No data sources specified." if data.empty?

    logger.debug "Metadata inputs:"
    meta.each { |m| logger.debug m }
    logger.debug "Data inputs:"
    data.each { |d| logger.debug d }

    ######################
    # Begin ingest process
    ######################
    start_overall = Time.zone.now
    ingests = 0

    logger.info(
      "Import start time: #{start_overall.strftime("%Y-%m-%d %H:%M:%S")}"
    )

    cli_opts = { meta: meta,
                 data: data,
                 options: options,
                 logger: logger, }

    begin
      AdminPolicy.ensure_admin_policy_exists

      case options[:format]
      when "csv"
        ingests = Importer::CSV.import(cli_opts)
      when "mods"
        ingests = Importer::MODS.import(cli_opts)
      when "etd"
        ingests = Importer::ETD.import(cli_opts)
      when "cyl"
        begin
          importer = Importer::Cylinder.new(cli_opts)
          importer.run
        rescue => e
          logger.error e
          logger.error e.backtrace
          raise IngestError,
                reached: options[:skip] + importer.imported_records_count
        ensure
          ingests = importer.imported_records_count
        end
      end # case/when

      end_overall = Time.zone.now

      logger.info "Ingested #{ingests} records in "\
                  "#{(end_overall - start_overall) / 60} minutes"
    rescue IngestError => e
      logger.info "To continue this ingest, re-run the command with "\
                   "`--skip #{e.reached}`"
    end
  end
end
