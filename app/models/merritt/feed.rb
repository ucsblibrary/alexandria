# frozen_string_literal: true

class Merritt::Feed < ActiveRecord::Base
  self.table_name_prefix = "merritt_"

  HOME = "https://merritt.cdlib.org"

  def self.etd_feed_url(page = 1)
    HOME + "/object/recent.atom?collection=ark:/13030/m5pv6m0x&page=#{page}"
  end

  def self.parse(page = 1)
    url = etd_feed_url(page)
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.request request

    if response.code.to_i != 200
      raise StandardError,
            "Error in Merritt::Feed.parse:"\
            "#{url} returned #{response.code} #{response.message}"
    end

    xml = response.body
    Feedjira.parse(xml)
  end

  def self.create_or_update(page, last_modified)
    merritt_feed = Merritt::Feed.find_or_create_by!(last_parsed_page: page)
    merritt_feed.last_modified = last_modified
    merritt_feed.save!
  end

  # Feed pages are available as
  # links in the following order
  # current, first, last & next
  def self.current_page
    parse.links.first.split("&").last.split("=").last.to_i
  end

  def self.first_page
    parse.links[1].split("&").last.split("=").last.to_i
  end

  def self.last_page
    parse.links[2].split("&").last.split("=").last.to_i
  end

  def self.last_modified
    parse.last_modified
  end
end
