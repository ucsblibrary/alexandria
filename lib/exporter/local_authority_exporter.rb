module Exporter
  class LocalAuthorityExporter

    attr_reader :export_dir, :export_file_name, :export_file
    attr_reader :temp_file_name, :temp_file

    # Some local authorities can have multiple labels, so we
    # don't know ahead of time how many columns the CSV file
    # will need.  As we process the fedora objects, use the
    # :max_names variable to keep track of the object with the
    # most labels.
    attr_accessor :max_names

    def initialize(dir = nil, file_name = nil)
      @export_dir = dir || default_dir
      @export_file_name = file_name || default_file_name
      @export_file = File.join(export_dir, export_file_name)
      @temp_file_name = File.basename(export_file_name, '.*') + '.tmp'
      @temp_file = File.join(export_dir, temp_file_name)
      @max_names = 1
    end

    def default_dir
      File.join(Rails.root, 'tmp', 'exports')
    end

    def default_file_name
      time = Time.now.strftime("%Y_%m_%d_%H%M%S")
      "export_authorities_#{time}.csv"
    end

    def run
      print_object_counts
      make_export_dir
      write_data_to_temp_file
      write_headers_and_data_to_export_file
      clean_up_temp_file
      puts "Export complete."
    end

    def print_object_counts
      puts "Number of local authorities to export:"
      LocalAuthority.local_authority_models.each do |model|
        puts "   #{model}: #{model.exact_model.count}"
      end
    end

    def make_export_dir
      FileUtils.mkdir_p(export_dir)
    end

    def write_data_to_temp_file
      CSV.open(temp_file, "w") do |csv|
        LocalAuthority.local_authority_models.each do |model|
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
      [object.class.to_s, object.id, object.public_uri] + names
    end

    # We don't know how many headers we'll need until after we
    # process all the fedora objects, so we need to add the
    # headers to the file after the data has been written.
    # In ruby there doesn't seem to be a nice way to prepend one
    # line to a file, so we write the headers to a new file and
    # then append the data from the temp file.
    def write_headers_and_data_to_export_file
      puts "Adding headers to data from temp file..."
      CSV.open(export_file, "w") do |csv|
        csv << headers
        CSV.foreach(temp_file) {|row| csv << row }
      end
      puts "Local authorities were exported to: #{export_file}"
    end

    def headers
      ['type', 'id', 'public_uri'] + Array.new(max_names){|i| 'name' }
    end

    def clean_up_temp_file
      FileUtils.rm(temp_file)
    end

  end
end
