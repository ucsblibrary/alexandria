require 'exporter/base_exporter'

module Exporter
  class LocalAuthorityExporter < BaseExporter

    attr_reader :temp_file_name, :temp_file

    # Some local authorities can have multiple labels, so we
    # don't know ahead of time how many columns the CSV file
    # will need.  As we process the fedora objects, use the
    # :max_names variable to keep track of the object with the
    # most labels.
    attr_accessor :max_names

    def initialize(dir = nil, file_name = nil)
      super
      @temp_file_name = File.basename(export_file_name, '.*') + '.tmp'
      @temp_file = File.join(export_dir, temp_file_name)
      @max_names = 1
    end

    def default_file_name
      "export_authorities_#{timestamp}.csv"
    end

    def classes_to_export
      LocalAuthority.local_authority_models
    end

    def print_object_counts
      puts 'Number of records to export:'
      classes_to_export.each do |model|
        puts "   #{model}: #{model.exact_model.count}"
      end
    end

    def export_data
      write_data_to_temp_file
      write_headers_and_data_to_export_file
      clean_up_temp_file
    end

    def write_data_to_temp_file
      CSV.open(temp_file, 'w') do |csv|
        classes_to_export.each do |model|
          puts "Exporting #{model} objects..."
          model.exact_model.each do |fedora_object|
            csv << object_data(fedora_object)
          end
        end
      end
    end

    def object_data(object)
      names = if object.respond_to?(:foaf_name)
                object.foaf_name
              else
                object.label
              end
      names = Array(names)
      self.max_names = names.count if names.count > max_names
      [object.class.to_s, object.id] + names
    end

    # We don't know how many headers we'll need until after we
    # process all the fedora objects, so we need to add the
    # headers to the file after the data has been written.
    # In ruby there doesn't seem to be a nice way to prepend one
    # line to a file, so we write the headers to a new file and
    # then append the data from the temp file.
    def write_headers_and_data_to_export_file
      puts 'Adding headers to data from temp file...'
      CSV.open(export_file, 'w') do |csv|
        csv << headers
        CSV.foreach(temp_file) { |row| csv << row }
      end
    end

    def headers
      %w(type id) + Array.new(max_names) { |_i| 'name' }
    end

    def clean_up_temp_file
      FileUtils.rm(temp_file)
    end
  end
end
