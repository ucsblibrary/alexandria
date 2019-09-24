# frozen_string_literal: true

module Merritt::Feed
  HOME = "https://merritt.cdlib.org"

  def self.etd_feed_url(page = 1)
    HOME + "/object/recent.atom?collection=ark:/13030/m5pv6m0x&page=#{page}"
  end

  def self.parse(page = 1)
    url = etd_feed_url(page)
    resp = HTTParty.get(url)
    if resp.code != 200
      raise StandardError,
            "Error in Merritt::Feed.parse:"\
            "#{url} returned #{resp.code} #{resp.message}"
    end
    xml = resp.body
    Feedjira.parse(xml)
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
