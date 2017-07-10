# frozen_string_literal: true

require "sru"

module Importer::ETDParser
  # @param [String] xml_file_name The path to a ProQuest XML file
  # @return [String]
  def self.extract_binary_filename(xml_file_name)
    Nokogiri::XML(
      File.open(xml_file_name)
    ).css("DISS_binary").children.first.to_s
  end

  # @param [String] xml_file_name The path to a ProQuest XML file
  # @return [String]
  def self.parse_file(xml_file_name)
    binary_filename = extract_binary_filename(xml_file_name)
    SRU.by_binary(binary_filename)
  end
end
