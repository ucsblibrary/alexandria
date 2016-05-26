require 'csv'
require File.expand_path('../factory', __FILE__)

module Importer::CSV
  # Match headers like "lc_subject_type"
  TYPE_HEADER_PATTERN = /\A.*_type\Z/

  # @param [String, Pathname] metadata
  # @return [Array]
  def self.split(metadata)
    csv = ::CSV.read(metadata)
    [csv.first, csv.slice(1, csv.length)]
  end

  # @param [Hash] options
  # @option options [Array] :files
  # @option options [Hash] :attributes The attributes hash generated
  #   by {Importer::CSV.csv_attributes}
  #
  # @return [Void]
  def self.import(options = {})
    files = options.fetch(:files, [])
    attributes = options.fetch(:attributes, {})

    begin
      model = attributes.delete(:type)
      raise NoModelError if model.nil? || model.empty?
      ::Importer::Factory.for(model).new(
        attributes.merge(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID),
        files
      ).run
    rescue => e
      $stderr.puts e
      $stderr.puts e.backtrace
      raise IngestError
    end
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
end
