# frozen_string_literal: true

require "metadata_ci"

module Parse::CSV
  # Match headers like "lc_subject_type"
  TYPE_HEADER_PATTERN = /\A.*_type\Z/

  # Given a 'type' field from the CSV, determine which object model pertains
  # @param [String] csv_type_field
  # @return [String] the name of the model class
  def self.determine_model(csv_type_field)
    csv_type_field.titleize.gsub(/\s+/, "")
  end

  # Maps a row of CSV metadata to the CSV headers
  #
  # @param [CSV::Row] row
  # @return [Hash]
  def self.csv_attributes(row)
    {}.tap do |processed|
      # we use #with_index and pass the indices to the field instead
      # of the header because there may be multiple instances of the
      # same header, e.g., :files
      row.headers.map.with_index do |header, i|
        extract_field(header.to_s, row.field(i).to_s, processed)
      end
    end
  end

  # @param [String] header the column heading
  # @param [String] val the associated value
  # @param [Hash] processed
  def self.extract_field(header, val, processed)
    return if val.blank?
    raise "No header corresponds to value '#{val}'" if header.blank?

    case header
    when "type", "id"
      # type and id are singular
      processed[header.to_sym] = val
    when /^(created|issued|date_copyrighted|date_valid)_(.*)$/
      key = "#{Regexp.last_match(1)}_attributes".to_sym
      # TODO: this only handles one date of each type
      processed[key] ||= [{}]
      update_date(processed[key].first, Regexp.last_match(2), val)
    when "work_type"
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

  # Given an accession_number, get the id of the associated object
  # @param [Array|String] accession_number
  # @return [String] the id of the associated object or nil if nothing found
  def self.get_id_for_accession_number(accession_number)
    a = if accession_number.instance_of? Array
          accession_number.first
        else
          accession_number
        end
    o = ActiveFedora::Base.where(accession_number_ssim: a).first
    return o.id if o
    nil
  end

  # Transform coordinates as provided in CSV spreadsheet into dcmi-box
  # formatting
  #
  # Output should look like 'northlimit=43.039; eastlimit=-69.856;
  # southlimit=42.943; westlimit=-71.032; units=degrees;
  # projection=EPSG:4326'
  #
  # TODO: The transform_coordinates_to_dcmi_box method should invoke a
  # DCMIBox.new method DCMI behaviors should be encapsulated there and
  # it should have a .to_s method
  #
  # @param [Hash] attrs A hash of attributes that will become a fedora object
  # @return [Hash]
  def self.transform_coordinates_to_dcmi_box(attrs)
    return attrs unless attrs[:north_bound_latitude] ||
                        attrs[:east_bound_longitude] ||
                        attrs[:south_bound_latitude] ||
                        attrs[:west_bound_longitude]

    if attrs[:north_bound_latitude]
      north = "northlimit=#{attrs.delete(:north_bound_latitude).first}; "
    end

    if attrs[:east_bound_longitude]
      east = "eastlimit=#{attrs.delete(:east_bound_longitude).first}; "
    end

    if attrs[:south_bound_latitude]
      south = "southlimit=#{attrs.delete(:south_bound_latitude).first}; "
    end

    if attrs[:west_bound_longitude]
      west = "westlimit=#{attrs.delete(:west_bound_longitude).first}; "
    end

    attrs[:coverage] = "#{north}#{east}#{south}#{west}units=degrees; "\
                       "projection=EPSG:4326"
    attrs
  end

  # Process the structural metadata, e.g., parent_id, index_map_id
  #
  # @param [Hash] attrs A hash of attributes that will become a fedora object
  # @param [Hash]
  def self.handle_structural_metadata(attrs)
    a = attrs.delete(:parent_accession_number)
    if a
      parent_id = get_id_for_accession_number(a)
      attrs[:parent_id] = parent_id if parent_id
    end

    # This is an attribute of MapSets, which are generally created
    # before the IndexMap specified in the metadata.  If we use
    # {get_id_for_accession_number}, we'll be setting this attribute
    # to nil since the IndexMap doesn't exist in Fedora yet.  So
    # instead just use the accession number itself.
    im = attrs.delete(:index_map_accession_number)
    attrs[:index_map_id] = im if im.present?

    attrs
  end

  # @param [String] header
  # @param [String] val
  # @param [Hash] processed
  # @param [Symbol] key
  def self.extract_multi_value_field(header, val, processed, key = nil)
    key ||= header.to_sym
    processed[key] ||= []
    val = val.strip
    processed[key] << (::Fields::URI.looks_like_uri?(val) ? RDF::URI(val) : val)
  end

  # Fields that have an associated *_type column
  #
  # @param [String] header
  # @param [String] val
  # @param [Hash] processed
  def self.update_typed_field(header, val, processed)
    if header.match(TYPE_HEADER_PATTERN)
      stripped_header = header.gsub("_type", "")
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
    val = [val] unless %w[admin_policy_id id].include? field
    collection[field.to_sym] = val
  end

  def self.update_date(date, field, val)
    date[field.to_sym] ||= []
    date[field.to_sym] << val
  end

  # Sometimes spaces or punctuation make their way into CSV field names.
  # When they do, clean it up.
  #
  # @param [Hash] attrs A hash of attributes that will become a fedora object
  # @return [Hash] the same hash, but with spaces stripped off all the
  #     field names
  def self.strip_extra_spaces(attrs)
    new_h = {}
    attrs.each_pair do |k, v|
      new_k = k.to_s.strip.to_sym
      new_h[new_k] = v
    end
    new_h
  end

  # Given a shorthand string for an access policy,
  # assign the right AccessPolicy object.
  #
  # @param [Hash] attrs A hash of attributes that will become a fedora object
  # @return [Hash]
  def self.assign_access_policy(attrs)
    raise "No access policy defined" unless attrs[:access_policy]
    access_policy = attrs.delete(:access_policy).first
    case access_policy
    when "public"
      attrs[:admin_policy_id] = AdminPolicy::PUBLIC_POLICY_ID
    when "ucsb"
      attrs[:admin_policy_id] = AdminPolicy::UCSB_POLICY_ID
    when "discovery"
      attrs[:admin_policy_id] = AdminPolicy::DISCOVERY_POLICY_ID
    when "public_campus"
      attrs[:admin_policy_id] = AdminPolicy::PUBLIC_CAMPUS_POLICY_ID
    when "restricted"
      attrs[:admin_policy_id] = AdminPolicy::RESTRICTED_POLICY_ID
    when "ucsb_campus"
      attrs[:admin_policy_id] = AdminPolicy::UCSB_CAMPUS_POLICY_ID
    else
      raise "Invalid access policy: #{access_policy}"
    end
    attrs
  end
end
