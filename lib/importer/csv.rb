require 'csv'
require File.expand_path('../factory', __FILE__)

# Import CSV files

module Importer::CSV

  include Importer::ImportLogger

  # Match headers like "lc_subject_type"
  TYPE_HEADER_PATTERN = /\A.*_type\Z/

  # The method called by bin/ingest
  # @param [Array] meta
  # @param [Array] data
  # @param [Hash] options See the options specified with Trollop in {bin/ingest}
  # @return [Int] The number of records ingested
  def self.import(meta, data, options)

    self.parse_log_options(options)

    logger.debug "Starting import with options #{options.inspect}"

    ingests = 0

    meta.each do |m|
      logger.info "Importing file #{m}"
      head, tail = split(m)

      if options[:skip] >= tail.length
        raise ArgumentError,
              "Number of records skipped (#{options[:skip]}) greater than total records to ingest"
      end

      tail.each do |row|
        attrs = csv_attributes(head, row)

        if options[:skip] > ingests
          logger.info "Skipping record #{ingests}: accession number #{attrs[:accession_number].first}"
          ingests += 1
          next
        end
        next if options[:number] && options[:number] <= ingests

        start_record = Time.now

        logger.info "Ingesting record #{ingests}: accession number #{attrs[:accession_number].first}"

        files = if attrs[:files].nil?
                  []
                else
                  data.select { |d| attrs[:files].include? File.basename(d) }
                end

        if options[:verbose]
          puts
          puts "Object attributes for item #{ingests + 1}:"
          puts attrs.each { |k, v| puts "#{k}: #{v}" }
          puts
          puts "Associated files for item #{ingests + 1}:"
          puts files.each { |f| puts f }
        end

        attrs = Importer::CSV.assign_access_policy(attrs)
        model = attrs.delete(:type)
        raise NoModelError if model.nil? || model.empty?

        o = ::Importer::Factory.for(model).new(attrs, files).run
        logger.info "accession_number #{attrs[:accession_number].first} ingested as #{o.id}"

        end_record = Time.now
        puts "Ingested record #{ingests + 1} of #{tail.length} in #{end_record - start_record} seconds"
        ingests += 1
      end
    end
    ingests
  rescue => e
    puts e
    puts e.backtrace
    raise IngestError.new(reached: ingests)
  rescue Interrupt
    puts "\nIngest stopped, cleaning up..."
    raise IngestError.new(reached: ingests)
  end

  # Read in a CSV file and split it into nested arrays.
  # Check for character encoding problems.
  # @param [String, Pathname] metadata
  # @return [Array]
  def self.split(metadata)
    csv = nil
    begin
      csv = ::CSV.read(metadata, encoding: "UTF-8")
    rescue ArgumentError => e # Most likely this is "invalid byte sequence in UTF-8"
        logger.error "The file #{metadata} could not be read in UTF-8. The error was: #{e}. Trying ISO-8859-1"
        csv = ::CSV.read(metadata, encoding: "ISO-8859-1")
    rescue => e
        logger.error "Couldn't process file #{metadata}. The error was: #{e}."
        raise e
    end
    [csv.first, csv.slice(1, csv.length)]
  end


  # @param [Array] row
  # @return [Array]
  def self.validate_headers(row)
    row.compact!

    # Allow headers with the pattern *_type to specify the record type
    # for a local authority.  e.g. For an author, author_type might be
    # 'Person'.
    difference = (row - valid_headers).reject { |h| h.match(TYPE_HEADER_PATTERN) }

    raise "Invalid headers: #{difference.join(', ')}" unless difference.blank?

    validate_header_pairs(row)
    row
  end

  # If you have a header like lc_subject_type, the next
  # header must be the corresponding field (e.g. lc_subject)
  #
  # @param [Array] row
  def self.validate_header_pairs(row)
    errors = []
    row.each_with_index do |header, i|
      next if header == 'work_type'
      next unless header.match(TYPE_HEADER_PATTERN)
      next_header = row[i + 1]
      field_name = header.gsub('_type', '')
      if next_header != field_name
        errors << "Invalid headers: '#{header}' column must be immediately followed by '#{field_name}' column."
      end
    end
    raise errors.join(', ') unless errors.blank?
  end

  # @return [Array]
  def self.valid_headers
    Image.attribute_names + %w(id type note_type note files) +
      time_span_headers + collection_headers
  end

  # @return [Array]
  def self.time_span_headers
    %w(created issued date_copyrighted date_valid).flat_map do |prefix|
      TimeSpan.properties.keys.map { |attribute| "#{prefix}_#{attribute}" }
    end
  end

  # @return [Array]
  def self.collection_headers
    %w(collection_id collection_title collection_accession_number)
  end

  # Maps a row of CSV metadata to the CSV headers
  #
  # @param [Array] headers
  # @param [Array] row
  #
  # @return [Hash]
  def self.csv_attributes(headers, row)
    {}.tap do |processed|
      headers.each_with_index do |header, index|
        extract_field(header, row[index], processed)
      end
    end
  end

  # @param [String] header
  # @param [String] val
  # @param [Hash] processed
  def self.extract_field(header, val, processed)
    return unless val
    case header
    when 'type', 'id'
      # type and id are singular
      processed[header.to_sym] = val
    when /^(created|issued|date_copyrighted|date_valid)_(.*)$/
      key = "#{Regexp.last_match(1)}_attributes".to_sym
      # TODO: this only handles one date of each type
      processed[key] ||= [{}]
      update_date(processed[key].first, Regexp.last_match(2), val)
    when 'work_type'
      extract_multi_value_field(header, val, processed)
    when TYPE_HEADER_PATTERN
      update_typed_field(header, val, processed)
    when /^collection_(.*)$/
      processed[:collection] ||= {}
      update_collection(processed[:collection], Regexp.last_match(1), val)
    else
      last_entry = Array(processed[header.to_sym]).last
      if last_entry.is_a?(Hash) && !last_entry[:name]
        update_typed_field(header, val, processed)
      else
        extract_multi_value_field(header, val, processed)
      end
    end
  end

  # @param [String] header
  # @param [String] val
  # @param [Hash] processed
  # @param [Symbol] key
  def self.extract_multi_value_field(header, val, processed, key = nil)
    key ||= header.to_sym
    processed[key] ||= []
    val = val.strip
    processed[key] << (looks_like_uri?(val) ? RDF::URI(val) : val)
  end

  # @param [String] str
  def self.looks_like_uri?(str)
    str =~ %r{^https?:\/\/}
  end

  # Fields that have an associated *_type column
  #
  # @param [String] header
  # @param [String] val
  # @param [Hash] processed
  def self.update_typed_field(header, val, processed)
    if header.match(TYPE_HEADER_PATTERN)
      stripped_header = header.gsub('_type', '')
      processed[stripped_header.to_sym] ||= []
      processed[stripped_header.to_sym] << { type: val }
    else
      fields = Array(processed[header.to_sym])
      fields.last[:name] = val
    end
  end

  # @param [Hash] collection
  # @param [String] field
  # @param [String] val
  def self.update_collection(collection, field, val)
    val = [val] unless %w(admin_policy_id id).include? field
    collection[field.to_sym] = val
  end

  def self.update_date(date, field, val)
    date[field.to_sym] ||= []
    date[field.to_sym] << val
  end

  # Given a shorthand string for an access policy,
  # assign the right AccessPolicy object
  # @param [Hash] attrs A hash of attributes that will become a fedora object
  # @return [Hash]
  def self.assign_access_policy(attrs)
    access_policy = if attrs[:access_policy]
                      attrs.delete(:access_policy).first
                    else
                      'public'
                    end
    case access_policy
    when 'public'
      attrs[:admin_policy_id] = AdminPolicy::PUBLIC_POLICY_ID
    when 'ucsb'
      attrs[:admin_policy_id] = AdminPolicy::UCSB_POLICY_ID
    end
    attrs
  end


end # End of module
