class Merritt::Etd < ActiveRecord::Base
  
  def self.merritt_id(etd_entry)
    "ark"+ etd_entry.entry_id.split("ark").last
  end

  # includes proquest pdf, xml
  # & optional supplemental files
  def self.proquest_files(etd_entry)
    etd_entry.links.select{|l| l.match("ucsb_0035")}
  end

  def self.metadata_file(etd_entry)
    proquest_files(etd_entry).find {|f| f.match("xml")}
  end

  def self.dissertation_file(etd_entry)
    proquest_files(etd_entry).find {|f| f.match("pdf")}
  end

  def self.supplemental_files(etd_entry)
    proquest_files(etd_entry) - [metadata_file(etd_entry), dissertation_file(etd_entry)]
  end

  def self.metadata_file_url(etd_entry)
    Merritt::Feed::HOME + metadata_file(etd_entry)
  end

  def self.dissertation_file_url(etd_entry)
    Merritt::Feed::HOME + dissertation_file(etd_entry)
  end

  def self.supplemental_file_urls(etd_entry)
    supplemental_files(etd_entry).map {|f| Merritt::Feed::HOME + f}
  end

  def self.create_etd(etd_entry)
    create!(
      merritt_id:     merritt_id(etd_entry),
      title:          etd_entry.title,
      author:         etd_entry.author,
      published_date: etd_entry.published_at,
      last_modified:  etd_entry.last_modified
    )
  end
end