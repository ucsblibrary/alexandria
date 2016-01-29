module Importer
  class CSVParser
    include Enumerable
    URI_FIELDS = %w(lc_subject language form_of_work institution rights_holder copyright_status license) + Metadata::MARCREL.keys.map(&:to_s)

    def initialize(file_name)
      @file_name = file_name
    end

    # @yieldparam attributes [Hash] the attributes from one row of the file
    def each(&_block)
      headers = nil
      CSV.foreach(@file_name) do |row|
        if headers
          yield attributes(headers, row)
        else
          headers = validate_headers(row)
        end
      end
    end

    private

      # Match headers like "lc_subject_type"
      def type_header_pattern
        /\A.*_type\Z/
      end

      def validate_headers(row)
        row.compact!
        difference = (row - valid_headers)

        # Allow headers with the pattern *_type to specify the
        # record type for a local authority.
        # e.g. For an author, author_type might be 'Person'.
        difference.delete_if {|h| h.match(type_header_pattern) }

        fail "Invalid headers: #{difference.join(', ')}" unless difference.blank?

        validate_header_pairs(row)
        row
      end

      # If you have a header like lc_subject_type, the next
      # header must be the corresponding field (e.g. lc_subject)
      def validate_header_pairs(row)
        errors = []
        row.each_with_index do |header, i|
          next if header == 'work_type' || header == 'note_type'
          if header.match(type_header_pattern)
            next_header = row[i + 1]
            field_name = header.gsub('_type', '')
            if next_header != field_name
              errors << "Invalid headers: '#{header}' column must be immediately followed by '#{field_name}' column."
            end
          end
        end
        fail errors.join(", ") unless errors.blank?
      end

      def valid_headers
        Image.attribute_names + %w(type note_value note_type files) +
          time_span_headers + collection_headers
      end

      def time_span_headers
        %w(created issued date_copyrighted date_valid).flat_map do |prefix|
          TimeSpan.properties.keys.map { |attribute| "#{prefix}_#{attribute}" }
        end
      end

      def collection_headers
        %w(collection_id collection_title collection_accession_number)
      end

      def attributes(headers, row)
        {}.tap do |processed|
          headers.each_with_index do |header, index|
            extract_field(header, row[index], processed)
          end
        end
      end

      def extract_field(header, val, processed)
        return unless val
        case header
        when 'type'
          # type is singular
          processed[header.to_sym] = val
        when /^(created|issued|date_copyrighted|date_valid)_(.*)$/
          key = "#{Regexp.last_match(1)}_attributes".to_sym
          # TODO: this only handles one date of each type
          processed[key] ||= [{}]
          update_date(processed[key].first, Regexp.last_match(2), val)
        when 'note_value', 'note_type'
          $stderr.puts "Note property: #{header} => #{val}"
        # TODO: extract notes
        when 'work_type'
          extract_multi_value_field(header, val, processed)
        when type_header_pattern
          update_local_authority(header, val, processed)
        when /^collection_(.*)$/
          processed[:collection] ||= {}
          update_collection(processed[:collection], Regexp.last_match(1), val)
        else
          last_entry = Array(processed[header.to_sym]).last
          if last_entry.is_a?(Hash) && !last_entry[:name]
            update_local_authority(header, val, processed)
          else
            extract_multi_value_field(header, val, processed)
          end
        end
      end

      def extract_multi_value_field(header, val, processed, key = nil)
        key ||= header.to_sym
        processed[key] ||= []
        processed[key] << (URI_FIELDS.include?(header) ? RDF::URI(val.rstrip) : val)
      end

      def update_local_authority(header, val, processed)
        if header.match(type_header_pattern)
          stripped_header = header.gsub('_type', '')
          processed[stripped_header.to_sym] ||= []
          processed[stripped_header.to_sym] << { type: val }
        else
          fields = Array(processed[header.to_sym])
          fields.last[:name] = val
        end
      end

      def update_collection(collection, field, val)
        val = [val] unless ['admin_policy_id', 'id'].include? field
        collection[field.to_sym] = val
      end

      def update_date(date, field, val)
        date[field.to_sym] ||= []
        date[field.to_sym] << val
      end
  end
end
