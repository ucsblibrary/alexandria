require 'pegasus'

module Importer::ETD
  # Uses metadata from ProQuest XML files to query Aleph and build a
  # MARCXML string
  #
  # @param [Array<String>] xml Paths to the ProQuest XML files
  # @return [String]
  def self.get_metadata(xml)
    marcxml = xml.map { |x| parse_file(x) }.compact
    ::Pegasus.wrap(marcxml)
  end

  # @param [String] xml_file_name The path to a ProQuest XML file
  # @return [String]
  def self.extract_binary_filename(xml_file_name)
    Nokogiri::XML(File.open(xml_file_name)).css('DISS_binary').children.first.to_s
  end

  # @param [String] xml_file_name The path to a ProQuest XML file
  # @return [String]
  def self.parse_file(xml_file_name)
    binary_filename = extract_binary_filename(xml_file_name)
    ::Pegasus.by_binary(binary_filename)
  end
end
