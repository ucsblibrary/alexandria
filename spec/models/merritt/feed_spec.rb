# frozen_string_literal: true

require "rails_helper"
require "httparty"

describe Merritt::Feed do
  let(:etd_path) { "/object/recent.atom?collection=ark:/13030/m5pv6m0x" }
  let(:etd_feed) { Merritt::Feed::HOME + etd_path }
  let(:page_one) { etd_feed + "&page=1" }
  let(:feed_file) { File.join(fixture_path, "merritt", "feed.xml") }
  let(:feed_parsed) { Feedjira.parse File.read(feed_file) }

  # TODO: Spec this out
  # describe ".parse" do
  #   describe "with http response code 404"; end
  #   describe "with http response code 200"; end
  # end

  before do
    VCR.turn_off!(ignore_cassettes: true)
    stub_request(:get, etd_feed)
      .to_return(headers: {}, body: File.read(feed_file), status: [200, "OK"])
    HTTParty.get(etd_feed)
  end

  describe ".etd_feed_url" do
    it "returns first page of the feed" do
      expect(described_class.etd_feed_url).to eq(page_one)
    end

    describe "when page parameter present" do
      it "returns requested page of the feed" do
        expect(described_class.etd_feed_url(2)).to eq(etd_feed + "&page=2")
      end
    end
  end

  describe "Feedjira parsed" do
    before { allow(described_class).to receive(:parse).and_return(feed_parsed) }

    describe ".current_page" do
      it "returns current page of the feed" do
        expect(described_class.current_page).to eq(1)
      end
    end

    describe ".first_page" do
      it "returns first page of the feed" do
        expect(described_class.first_page).to eq(1)
      end
    end

    describe ".last_page" do
      it "returns last page of the feed" do
        expect(described_class.last_page).to eq(311)
      end
    end
  end
end
