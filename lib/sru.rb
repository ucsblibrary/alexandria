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
    fetch(query: format(config[:ark_query],
                        ark_shoulder: config[:ark_shoulder],
                        ark: ark))
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
      # $stderr.puts "==> #{query}"
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

  def download_cylinders
    start_doc = fetch(
      query: "(alma.all_for_ui=http://www.library.ucsb.edu/OBJID/Cylinder*)"
    )

    marc_count = Nokogiri::XML(start_doc).css("numberOfRecords").text.to_i
    Rails.logger.info "Downloading #{marc_count} cylinders (this is slow)"

    all_marc = []
    marc_count.times do |i|
      marc = fetch(
        # left-pad the cylinder number with zeros when smaller than 4
        # digits
        query: format(config[:cylinder_query], number: i.to_s.rjust(4, "0"))
      )

      next if Nokogiri::XML(marc).css("numberOfRecords").text == "0"

      dest = File.join(Settings.marc_directory, "cylinder-#{i}.xml")

      File.open(dest, "w") do |f|
        f.write marc
        Rails.logger.info "Wrote #{dest}"
      end
      all_marc << strip(marc)
    end

    output = File.join(Settings.marc_directory, "cylinder-metadata.xml")
    File.open(output, "w") do |f|
      f.write wrap(all_marc.uniq)
      Rails.logger.info "Wrote cylinder-metadata.xml"
    end
  end

  def self.download_etds
    start_doc = fetch(query: config[:etd_query])
    marc_count = Nokogiri::XML(start_doc).css("numberOfRecords").text.to_i
    Rails.logger.info "Downloading #{marc_count} ETDs"

    all_marc = []
    next_record = 1
    while next_record < marc_count
      marc = fetch(query: config[:etd_query],
                   max: config[:batch_size],
                   start: next_record)

      output = File.join(
        Settings.marc_directory,
        format("etd-%05d-%05d.xml",
               next_record,
               (next_record + config[:batch_size] - 1))
      )

      File.open(output, "w") do |f|
        f.write marc

        num_written =
          MARC::XMLReader.new(StringIO.new(marc)).map { |r| r }.count

        Rails.logger.info "Wrote #{num_written} records to #{output}"
      end
      all_marc << strip(marc)
      next_record += config[:batch_size]
    end

    File.open(
      File.join(Settings.marc_directory, "etd-metadata.xml"), "w"
    ) do |f|
      f.write wrap(all_marc)
      Rails.logger.info "Wrote etd-metadata.xml"
    end
  end
end
