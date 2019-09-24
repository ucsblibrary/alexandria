# frozen_string_literal: true

module Merritt::IngestEtd
  COLLECTION = { accession_number: ["etds"] }.freeze

  def self.ingest(_merritt_id, file_path)
    # etd = ETD.where(id: merritt_id).first
    etd_files = unpack file_path
    extract_metadata etd_files[:xml]
  end

  def self.collection_exists?
    collection = Importer::Factory::CollectionFactory.new(
      COLLECTION,
      [],
      Logger.new(STDOUT)
    ).find

    collection.present? ? true : false
  end

  def self.unpack(file_path)
    etd_files = {
      xml: Dir["#{file_path}/*_DATA.xml"].first,
      pdf: Dir["#{file_path}/*.pdf"].first,
    }
    supplements = File.join(file_path, "supplements")
    if File.directory? supplements
      etd_files[:supplements] = Dir.glob File.join(supplements, "*.*")
    end
    etd_files
  end

  def self.extract_metadata(xml_path); end
end
