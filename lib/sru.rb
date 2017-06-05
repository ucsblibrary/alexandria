# frozen_string_literal: true

SRU_CONF = YAML.safe_load(
  ERB.new(File.read(Rails.root.join("config", "sru.yml"))).result
).freeze

module SRU
  PAYLOAD_HEADER = /<\?xml\ version="1\.0"\ .*<records>/m
  PAYLOAD_FOOTER = %r{<\/records>.*<\/searchRetrieveResponse>}m

  # @param [String] binary
  def self.by_binary(binary)
    fetch(query: "(marc.956.f=#{binary})")
  end

  # @param [String] ark
  def self.by_ark(ark)
    fetch(query: "(#{SRU_CONF["id_field"]}=#{SRU_CONF["ark_shoulder"]}/#{ark})")
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
              SRU_CONF["all_cylinders"]
            when :etd
              "(marc.947.a=pqd)"
            else
              raise ArgumentError,
                    "Bad :type #{options.fetch(:type)} for SRU.batch (should be :cylinder or :etd)"
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
    query = %W[
      #{SRU_CONF["host"]}
      ?
      #{SRU_CONF["default_params"].join("&")}
      &maximumRecords=#{options.fetch(:max, 1)}
      &startRecord=#{options.fetch(:start, 1)}
      &query=#{options.fetch(:query)}
    ].join("")

    client = HTTPClient.new

    begin
      search = client.get(query)
    rescue => e
      $stderr.puts "Error for query #{query}: #{e.message}"
      raise e
    end

    result = search.body
    if result.include? "<diagnostics>"
      message = Nokogiri::XML(result).xpath("//diag:message").first.text
      raise "Error for query #{query}: \"#{message}\""
    elsif result.include? "numberOfRecords>0<"
      $stderr.puts "Nothing found for #{query}"
      return ""
    end
    result
  end

  # @param [String] payload The MARCXML returned by the SRU API
  # @return [String]
  def self.strip(payload)
    payload.sub(PAYLOAD_HEADER, "").sub(PAYLOAD_FOOTER, "")
  end

  # @param [Array] records
  def self.wrap(records)
    <<~EOS
      <?xml version="1.0"?>
      <searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/">
        <version>1.2</version>
        <numberOfRecords>#{records.count}</numberOfRecords>
        <records>
          #{records.map { |r| strip(r) }.join("\n")}
        </records>
      </searchRetrieveResponse>
    EOS
  end
end
