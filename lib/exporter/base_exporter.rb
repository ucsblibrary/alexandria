module Exporter
  class BaseExporter
    attr_reader :export_dir, :export_file_name, :export_file

    def initialize(dir = nil, file_name = nil)
      @export_dir = dir || default_dir
      @export_file_name = file_name || default_file_name
      @export_file = File.join(export_dir, export_file_name)
    end

    def default_dir
      File.join(Rails.root, 'tmp', 'exports')
    end

    def timestamp
      @timestamp ||= Time.now.strftime('%Y_%m_%d_%H%M%S')
    end

    def run
      print_object_counts
      make_export_dir
      export_data
      print_export_complete
    end

    def print_object_counts
      # Override this method in the subclass
    end

    def make_export_dir
      FileUtils.mkdir_p(export_dir)
    end

    def export_data
      # Override this method in the subclass
    end

    def print_export_complete
      puts "Records were exported to: #{export_file}"
      puts 'Export complete.'
    end
  end
end
