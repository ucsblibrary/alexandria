# frozen_string_literal: true

require "net/https"
require "uri"

module Importer::Merritt::Etd
  include Importer::Merritt::Feed

  # metadata, dissertation
  # & supplemental files
  def self.import(etd)
    # tmp/merrittetds
    merritt_etd_dir = Settings.merritt_etd_dir
    Dir.mkdir merritt_etd_dir unless File.directory? merritt_etd_dir
    # tmp/merrittetds/download_m5bp580k
    download_path = File.join(merritt_etd_dir, "download_#{ark(etd)}")
    Dir.mkdir download_path unless File.directory? download_path

    [metadata_url(etd), dissertation_url(etd)].each do |url|
      # tmp/merrittetds/download_m5bp580k/Soriano_ucsb_0035N_14420_DATA.xml
      # tmp/merrittetds/download_m5bp580k/Soriano_ucsb_0035N_14420.pdf
      file_path = File.join(download_path, escape_encodings(url))
      create_poquest_file(file_path, url)
    end

    if supp_urls(etd).present?
      # tmp/merrittetds/download_m5bp580k/supplements
      supp_path = File.join(download_path, "supplements")
      Dir.mkdir(supp_path) unless File.directory?(supp_path)

      supp_urls(etd).each do |supp_url|
        # tmp/merrittetds/download_m5bp580k/supplements/Soriano_ucsb_0035N_67
        sub_dir = File.join(supp_path, escape_encodings(supp_url).split("/").first)
        Dir.mkdir(sub_dir) unless File.directory?(sub_dir)

        # tmp/merrittetds/download_m5bp580k/supplements/Soriano_ucsb_0035N_67/av.jpeg
        supp_file_path = File.join(sub_dir,
                                   escape_encodings(supp_url).split("/").last)
        create_poquest_file(supp_file_path, supp_url)
      end
    end
  end

  def self.ark(etd)
    etd.entry_id.split("/").last
  end

  # includes proquest pdf, xml
  # & optional supplemental files
  def self.proquest_files(etd)
    etd.links.select { |l| l.match("ucsb_0035") }
  end

  def self.metadata_file(etd)
    proquest_files(etd).find { |f| f.match("xml") }
  end

  def self.dissertation_file(etd)
    proquest_files(etd).find { |f| f.match("pdf") }
  end

  def self.supp_files(etd)
    proquest_files(etd) - [metadata_file(etd), dissertation_file(etd)]
  end

  def self.metadata_url(etd)
    HOME + metadata_file(etd)
  end

  def self.dissertation_url(etd)
    HOME + dissertation_file(etd)
  end

  def self.supp_urls(etd)
    supp_files(etd).map { |f| HOME + f }
  end

  def self.get_content(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(Rails.application.config.merritt_user,
                       Rails.application.config.merritt_pwd)
    http.request(request)
  end

  def self.escape_encodings(url)
    # double unescape urls to convert encodings
    # like %252F => %2F => / in urls as shown below
    # https://merritt.cdlib.org/d/ark:/13030/m5t73653/9
    # /producer/etdadmin_upload_221812/Egan_ucsb_0035D_11645_DATA.xml
    str = CGI.unescape(CGI.unescape(url))
    str.split("producer/").last
    str.split("/").last
  end

  def self.create_poquest_file(file_path, url)
    File.open(file_path, "wb") do |f|
      f.write get_content(url).body
    end
  end
end
