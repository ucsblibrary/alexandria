# frozen_string_literal: true

require "net/https"
require "uri"

module Importer::Merritt::Etd
  include Importer::Merritt::Feed

  # metadata, dissertation
  # & supplemental files
  def self.import(etd)
    merritt_etd_dir = Settings.merritt_etd_dir
    Dir.mkdir merritt_etd_dir unless File.directory? merritt_etd_dir
    file_path = File.join(merritt_etd_dir, "download_#{ark(etd)}")
    Dir.mkdir(file_path) unless File.directory?(file_path)

    [metadata_url(etd), dissertation_url(etd)].each do |url|
      create_poquest_file(file_path, url)
    end

    if supp_urls(etd).present?
      supp_path = File.join(file_path, "supplements")
      Dir.mkdir(supp_path) unless File.directory?(supp_path)
      supp_urls(etd).each do |supp_url|
        create_poquest_file(supp_path, supp_url)
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
    # double unescape to handle %252F in urls like
    # Barel_ucsb_0035D_67%252FSmall%2520Town.zip
    str = CGI.unescape(CGI.unescape(url))
    str.split("producer/").last
  end

  def self.create_poquest_file(file_path, url)
    File.open(File.join(file_path, escape_encodings(url)), "wb") do |f|
      f.write get_content(url).body
    end
  end
end
