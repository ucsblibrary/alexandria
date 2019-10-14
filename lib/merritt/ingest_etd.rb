# frozen_string_literal: true

module Merritt::IngestEtd
  def self.ingest(merritt_id, file_path)
    raise CollectionNotFound, "ETD Collection Not Found" if collection.blank?
    # etd = ETD.where(id: merritt_id).first
    files = unpack(file_path)
    attribs = extract_metadata(merritt_id, files[:xml])
    IngestJob.perform_later(
      model: "ETD",
      attrs: attribs.to_json,
      files: files
    )
  end

  def self.unpack(file_path)
    etd_files = {
      xml: Dir["#{file_path}/*_DATA.xml"].first,
      pdf: Dir["#{file_path}/*.pdf"].first,
      supplements: [],
    }
    supplements = File.join(file_path, "supplements")
    if File.directory? supplements
      etd_files[:supplements] = Dir.glob File.join(supplements, "*.*")
    end
    etd_files
  end

  def self.extract_metadata(merritt_id, xml_path)
    xml = File.open(xml_path) { |f| Nokogiri::XML(f) }
    {
      id:         Identifier.merritt_ark_to_id(merritt_id),
      identifier: [merritt_id],
      merritt_id: [merritt_id],
      local_collection_id: [collection.id],
    }.merge(Proquest::XML.metadata_attribs(xml))
  end

  def self.collection
    Collection.where(accession_number: ["etds"]).first
  end
end
