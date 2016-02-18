require 'exporter/base_exporter'

# Export the ID and ARK for fedora records.
# This is meant to be used for data migration, so that when new
# records are created, they will have the same ARK as the old
# records.

module Exporter
  class IdExporter < BaseExporter

    def default_file_name
      "export_ids_#{timestamp}.csv"
    end

    def classes_to_export
      [Collection, Image, ETD]
    end

    def print_object_counts
      puts 'Number of records to export:'
      classes_to_export.each do |model|
        puts "   #{model}: #{model.count}"
      end
    end

    def export_data
      CSV.open(export_file, 'w') do |csv|
        csv << headers
        classes_to_export.each do |model|
          puts "Exporting #{model} objects..."
          model.find_each do |fedora_object|
            csv << object_data(fedora_object)
          end
        end
      end
    end

    def headers
      %w(type id accession_number identifier title)
    end

    def object_data(object)
      [object.class.to_s, object.id, object.accession_number.first, object.ark, Array(object.title).first]
    end

  end
end
