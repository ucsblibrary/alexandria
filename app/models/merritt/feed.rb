class Merritt::Feed < ActiveRecord::Base
  HOME = "https://merritt.cdlib.org"

  def self.etd_feed_url(page=1)
    HOME + "/object/recent.atom?collection=ark:/13030/m5pv6m0x&page=#{page}"
  end

  def self.parse(page=1)
    url = etd_feed_url(page)
    response = HTTParty.get(url)
    # TODO: This does not belong here
    # Figure out better error handling
    # raise "Merritt Feed Error: #{response.code} #{response.message}" if response.code != 200
    xml = response.body
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

  def self.create_feed(page=1)
    feed = parse(page)
    create!(
      repo_url:   etd_feed_url(page),
      page_num:   page,
      updated:    feed.updated.to_datetime,
      work_type:  work_type
    )
  end
end
