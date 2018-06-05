# frozen_string_literal: true

SRU_CONF = YAML.safe_load(
  ERB.new(File.read(Rails.root.join("config", "sru.yml"))).result
).freeze

module SRU
  PAYLOAD_HEADER = /<\?xml\ version="1\.0"\ .*<records>/m
  PAYLOAD_FOOTER = %r{<\/records>.*<\/searchRetrieveResponse>}m

  def self.config
    @config ||= SRU_CONF.with_indifferent_access
  end

  # @param [String] binary
  def self.by_binary(binary)
    fetch(query: format(config[:binary_query],
                        binary: binary))
  end

  # @param [String] ark
  def self.by_ark(ark)
    fetch(query: format(config[:ark_query], ark: ark))
  end

  # @param [Hash] options
  # @option options [String] :query
  # @option options [Int] :max
  # @option options [Int] start
  #
  # @return [String]
  def self.fetch(options)
    query = %W[
      #{config["host"]}
      ?
      #{config["default_params"].join("&")}
      &maximumRecords=#{options.fetch(:max, 1)}
      &startRecord=#{options.fetch(:start, 1)}
      &query=#{options.fetch(:query)}
    ].join("")

    client = HTTPClient.new

    begin
      puts "Fetching #{query}"
      search = client.get(query)
    rescue StandardError => e
      warn "Error for query #{query}: #{e.message}"
      raise e
    end

    result = search.body
    if result.include? "<diagnostics>"
      message = Nokogiri::XML(result).xpath("//diag:message").first.text
      raise "Error for query #{query}: \"#{message}\""
    elsif result.include? "numberOfRecords>0<"
      warn "Nothing found for #{query}"
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
          #{records.flatten.map { |r| strip(r) }.join("\n")}
        </records>
      </searchRetrieveResponse>
    EOS
  end

  def self.download_etds(number:, skip: 0)
    start_doc = fetch(query: config["etd_query"])
    marc_count = number || Nokogiri::XML(start_doc).css("numberOfRecords").text.to_i

    if marc_count > 10_000
      warn "More than 10,000 ETDs found; downloading the first 10,000"
    end

    batches = marc_count / config[:batch_size]
    skip_batches = skip / config[:batch_size]
    download_batches = Array.new(batches) { |i| i }.drop(skip_batches)

    all = download_batches.map do |i|
      start = ((i * config[:batch_size]) + 1) + (skip % config[:batch_size])
      strip(download_range(:etd, start, config[:batch_size]))
    end

    remainder = marc_count % config[:batch_size]
    if remainder.positive?
      leftover = (marc_count - remainder + 1) + (skip % config[:batch_size])
      all << download_range(:etd, leftover, remainder)
    end

    output = File.join(Settings.marc_directory, "etd-metadata.xml")
    File.open(output, "w") do |f|
      f.write wrap(all)
      num = MARC::XMLReader.new(StringIO.new(wrap(all))).map { |r| r }.count
      Rails.logger.info "Wrote #{num} records to #{output}"
    end
  end

  def self.download_cylinders(number:, skip: 0)
    start_doc = fetch(query: config["cylinder_query"])
    total_record_count = Nokogiri::XML(start_doc).css("numberOfRecords").text.to_i

    marc_count = number || total_record_count

    if skip > total_record_count
      warn "Records to be skipped (#{skip}) "\
           "greater than total record count (#{total_record_count})"
      return
    end

    all = Array.new(marc_count) do |i|
      cyl_number = (i + 1 + skip).to_s.rjust(4, "0")

      marc = fetch(
        query: format(config[:cylinder_query_single], number: cyl_number)
      )
      next if Nokogiri::XML(marc).css("numberOfRecords").text == "0"

      output = File.join(Settings.marc_directory, "cylinder-#{cyl_number}.xml")

      File.open(output, "w") do |f|
        f.write marc
        Rails.logger.info "Wrote #{output}"
      end

      marc
    end.compact

    output = File.join(Settings.marc_directory, "cylinder-metadata.xml")
    File.open(output, "w") do |f|
      f.write wrap(all)
      num = MARC::XMLReader.new(StringIO.new(wrap(all))).map { |r| r }.count
      Rails.logger.info "Wrote #{num} records to #{output}"
    end
  end

  # @param [Symbol] type
  # @param [Integer] start
  # @param [Integer] number
  def self.download_range(type, start, number)
    marc_batch = fetch(query: config["#{type}_query"],
                       max: number,
                       start: start)

    output = File.join(
      Settings.marc_directory,
      format("%s-%05d-%05d.xml", type, start, (start + number - 1))
    )

    File.open(output, "w") do |f|
      f.write marc_batch

      num = MARC::XMLReader.new(StringIO.new(marc_batch)).map { |r| r }.count
      Rails.logger.info "Wrote #{num} records to #{output}"
    end

    marc_batch
  end
end
