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

      def validate_headers(row)
        difference = (row - valid_headers)
        fail "Invalid headers: #{difference.join(', ')}" unless difference.blank?
        row
      end

      def valid_headers
        Image.attribute_names + %w(type note_value note_type files) +
          time_span_headers + collection_headers
      end

      def time_span_headers
        %w(created issued date_copyrighted date_valid).flat_map do |prefix|
          TimeSpan.attribute_names.map { |attribute| "#{prefix}_#{attribute}" }
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
        when 'title', 'type'
          # title and type are singular
          processed[header.to_sym] = val
        when /^(created|issued|date_copyrighted|date_valid)_(.*)$/
          key = "#{Regexp.last_match(1)}_attributes".to_sym
          # TODO: this only handles one date of each type
          processed[key] ||= [{}]
          update_date(processed[key].first, Regexp.last_match(2), val)
        when 'note_value', 'note_type'
          $stderr.puts "Note property: #{header} => #{val}"

        # TODO: extract notes
        when 'files'
          processed[:files] ||= []
          processed[:files] << val if val
        when /^collection_(.*)$/
          processed[:collection] ||= {}
          update_collection(processed[:collection], Regexp.last_match(1), val)
        else
          # Everything else is multivalued
          processed[header.to_sym] ||= []
          processed[header.to_sym] << (URI_FIELDS.include?(header) ? RDF::URI(val.rstrip) : val)
        end
     end

      def update_collection(collection, field, val)
        val = [val] if field == 'accession_number'
        collection[field.to_sym] = val
      end

      def update_date(date, field, val)
        date[field.to_sym] ||= []
        date[field.to_sym] << val
      end
  end
end
