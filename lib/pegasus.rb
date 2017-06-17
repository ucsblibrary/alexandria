# frozen_string_literal: true

module Pegasus
  # rubocop:disable Metrics/LineLength
  SRU = "#{Rails.application.secrets.sru_host}/sba01pub?version=1.1&operation=searchRetrieve"
  ARK_SHOULDER = "ark..48907"
  PAYLOAD_HEADER = "<?xml version=\"1.0\"?>\n<zs:searchRetrieveResponse xmlns:zs=\"http://www.loc.gov/zing/srw/\"><zs:version>1.1</zs:version><zs:numberOfRecords>1</zs:numberOfRecords><zs:records>"
  PAYLOAD_FOOTER = "</zs:records></zs:searchRetrieveResponse>"
  # rubocop:enable Metrics/LineLength

  # @param [String] binary
  def self.by_binary(binary)
    fetch(query: "(marc.956.f=#{binary})")
  end

  # @param [String] ark
  def self.by_ark(ark)
    fetch(query: "(marc.024.a=#{ARK_SHOULDER}.#{ark})")
  end

  # @param [Hash] options
  # @option options [Symbol] :type
  # @option options [Int] :max
  # @option options [Int] start
  #
  # @return [String]
  def self.batch(options)
    query = case options.fetch(:type)
            when :cylinder
              "(dc.format=wd)"
            when :etd
              "(marc.947.a=pqd)"
            else
              raise ArgumentError,
                    "Bad :type #{options.fetch(:type)} for "\
                    "Pegasus.batch (should be :cylinder or :etd)"
            end
    fetch(
      query: query,
      max: options.fetch(:max, 1),
      start: options.fetch(:start, 1)
    )
  end

  # @param [Hash] options
  # @option options [String] :query
  # @option options [Int] :max
  # @option options [Int] start
  #
  # @return [String]
  def self.fetch(options)
    query = [
      SRU,
      "&maximumRecords=#{options.fetch(:max, 1)}",
      "&startRecord=#{options.fetch(:start, 1)}",
      "&query=#{options.fetch(:query)}",
    ].join("")

    # $stderr.puts query

    client = HTTPClient.new
    search = client.get(query)

    result = search.body
    if result.include?("zs:numberOfRecords>0<")
      $stderr.puts "Nothing found for #{query}"
      return ""
    end
    result
  end

  # @param [String] payload The MARCXML returned by the Aleph API
  # @return [String]
  def self.strip(payload)
    payload.sub(PAYLOAD_HEADER, "").sub(PAYLOAD_FOOTER, "")
  end

  # @param [Array] records
  def self.wrap(records)
    <<~EOS
      <?xml version="1.0"?>
      <zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/"><zs:version>1.1</zs:version><zs:numberOfRecords>#{records.count}</zs:numberOfRecords><zs:records>
      #{records.map { |r| strip(r) }.join("\n")}
      </zs:records></zs:searchRetrieveResponse>
    EOS
  end
end
