module Importer
  module ETDImporter
    def self.write_marc_file(zipfiles, output_file)
      marcs = find_marc_for_zipfiles(zipfiles)
      puts "Copied zipfiles to #{Settings.proquest_directory}"

      File.open(File.join(Settings.marc_directory, output_file), 'w') do |f|
        f.write <<-EOS
<?xml version="1.0"?>
<zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/"><zs:version>1.1</zs:version><zs:numberOfRecords>#{marcs.count}</zs:numberOfRecords><zs:records>
      EOS
        f.write marcs.join("\n")
        f.write('</zs:records></zs:searchRetrieveResponse>')

        puts "Wrote MARC metadata to #{Settings.marc_directory}/"
      end
    end

    private

      # @param [String] zipfile The path to the .zip file
      #
      # @return [Array]
      def self.unzip(zipfile, dest)
        FileUtils.cp zipfile, Settings.proquest_directory

        xml ||= []
        system 'unzip', '-o', zipfile, '-d', dest

        Dir.glob("#{dest}/**/*.xml") do |x|
          puts "Found #{x}"
          xml << x
        end

        xml
      end

      def self.extract_binary_filename(xml_file_name)
        Nokogiri::XML(File.open(xml_file_name)).css('DISS_binary').children.first.to_s
      end

      def self.query_pegasus(binary_filename)
        search = Curl::Easy.perform("#{Rails.application.secrets.sru_host}/sba01pub?version=1.1&operation=searchRetrieve&maximumRecords=1&startRecord=1&query=(marc.947.a=pqd%20and%20marc.956.f=#{binary_filename})")
        result = search.body_str
        return false unless result.include?('zs:numberOfRecords>1')
        search.body_str
      end

      PAYLOAD_HEADER = "<?xml version=\"1.0\"?>\n<zs:searchRetrieveResponse xmlns:zs=\"http://www.loc.gov/zing/srw/\"><zs:version>1.1</zs:version><zs:numberOfRecords>1</zs:numberOfRecords><zs:records>".freeze
      PAYLOAD_FOOTER = '</zs:records></zs:searchRetrieveResponse>'.freeze

      def self.strip_wrapper(payload)
        payload.sub(PAYLOAD_HEADER, '').sub(PAYLOAD_FOOTER, '')
      end

      def self.parse_file(xml_file_name)
        binary_filename = extract_binary_filename(xml_file_name)
        result = query_pegasus(binary_filename)
        if !result
          $stderr.puts "Error: failed to retrieve record for #{binary_filename}"
        else
          strip_wrapper(result)
        end
      end

      def self.find_marc_for_zipfiles(zipfiles)
        temp = File.join(Settings.download_root, Time.now.to_i.to_s)
        Dir.mkdir temp
        marc = zipfiles.map { |f| unzip(f, temp) }.flatten.uniq
                .map { |x| parse_file(x) }
        FileUtils.rm_rf temp
        marc
      end
  end
end
