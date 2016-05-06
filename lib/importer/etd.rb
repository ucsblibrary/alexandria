# lib/proquest
require 'proquest'

module Importer::ETD
  # @param [Array<String>] xml Paths to the MARC XML files
  # @return [String]
  def self.fetch_marc(xml)
    marcs = xml.map { |x| parse_file(x) }

    <<-EOS
<?xml version="1.0"?>
<zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/"><zs:version>1.1</zs:version><zs:numberOfRecords>#{marcs.count}</zs:numberOfRecords><zs:records>
#{marcs.join("\n")}
</zs:records></zs:searchRetrieveResponse>
    EOS
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
end
