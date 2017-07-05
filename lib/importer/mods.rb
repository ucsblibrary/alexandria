# frozen_string_literal: true

module Importer::MODS
  # @param [String] meta
  # @param [Array<String>] data
  # @param [Hash] options See the options specified with Trollop in {bin/ingest}
  # @return [Image, Collection]
  def self.import(meta, data, options)
    if options[:skip] >= meta.length
      raise ArgumentError,
            "Number of records skipped (#{options[:skip]}) "\
            "greater than total records to ingest"
    end
    ingests = 0

    # TODO: this currently assumes one record per metadata file
    meta.each do |metadatum|
      if options[:skip] > ingests
        ingests += 1
        next
      end
      next if options[:number] && options[:number] <= ingests

      start_record = Time.zone.now
      ingest_mod(metadata: metadatum, data: data, options: options)
      end_record = Time.zone.now

      puts "Ingested record #{ingests + 1} of #{meta.length} "\
           "in #{end_record - start_record} seconds"

      ingests += 1
    end

    ingests
  rescue => e
    puts e
    puts e.backtrace
    raise IngestError, reached: ingests
  rescue Interrupt
    puts "\nIngest stopped, cleaning up..."
    raise IngestError, reached: ingests
  end

  def self.ingest_mod(metadata:, data:, options: {})
    selected_data = data.select do |f|
      # FIXME: find a more reliable test
      meta_base = File.basename(metadata, ".xml")
      data_base = File.basename(f, File.extname(f))
      data_base.include?(meta_base) || meta_base.include?(data_base)
    end

    if options[:verbose]
      puts
      puts "Object metadata:"
      puts metadata
      puts
      puts "Associated files:"
      selected_data.each { |f| puts f }
    end

    parser = Parser.new(metadata)

    ::Importer::Factory.for(parser.model.to_s).new(
      parser.attributes.merge(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID),
      selected_data
    ).run
  end

  class Parser
    ORIGIN_TEXT = "Converted from MODS 3.4 to local RDF profile by ADRL"

    NAMESPACES = { "mods" => Mods::MODS_NS }.freeze

    def initialize(file)
      @file = file
    end

    def model
      @model ||= if collection?
                   Collection
                 elsif image?
                   Image
                 end
    end

    def mods
      @mods ||= Mods::Record.new.from_file(@file)
    end

    def type_of_resource
      # MODS_RESOURCE_MAP defined in initializers/mods_resource_map.rb
      @type_of_resource ||= if collection?
                              # this is a very silly bit of code, but
                              # what it does is ensure that MODS
                              # Collections have their work_type be
                              # Collection /and/ all the formats of
                              # the items they contain
                              MODS_RESOURCE_MAP["collection"].merge(
                                uri: [
                                  MODS_RESOURCE_MAP["collection"][:uri],
                                  *mods.typeOfResource.content.map do |t|
                                    MODS_RESOURCE_MAP[t][:uri]
                                  end,
                                ].flatten
                              )
                            else
                              # return an empty hash in the case of
                              # XML fragments
                              MODS_RESOURCE_MAP[
                                mods.typeOfResource.content.first
                              ] || {}
                            end
    end

    def collection?
      type_keys = mods.typeOfResource.attributes.map(&:keys).flatten
      return false unless type_keys.include?("collection")

      mods.typeOfResource.attributes.any? do |hash|
        hash.fetch("collection").value == "yes"
      end
    end

    def image?
      type_of_resource[:label] == "Still image"
    end

    def attributes
      if model == Collection
        collection_attributes
      else
        record_attributes
      end
    end

    def record_attributes
      common_attributes.merge(
        files: mods.extension.xpath("./fileName").map(&:text),
        collection: collection,
        series_name: mods.xpath(
          "//mods:relatedItem[@type='series']",
          NAMESPACES
        ).titleInfo.title.map(&:text)
      )
    end

    def collection_attributes
      common_attributes
    end

    def common_attributes
      description
        .merge(dates)
        .merge(locations)
        .merge(rights)
        .merge(identifiers)
        .merge(relations)
        .merge(finding_aid)
    end

    def description
      {
        title: untyped_title,
        alternative: alt_title,
        description: mods_description,
        lc_subject: subject,
        extent: mods.physical_description.extent.map do |node|
          strip_whitespace(node.text)
        end,
        language: mods.language.languageTerm.valueURI.map do |uri|
          RDF::URI.new(uri)
        end,
        digital_origin: mods.physical_description.digitalOrigin.map(&:text),
        publisher: mods.origin_info.publisher.map(&:text),
        form_of_work: mods.genre.valueURI.map { |uri| RDF::URI.new(uri) },
        work_type: type_of_resource[:uri],
        citation: citation,
        notes_attributes: notes,
        record_origin: record_origin,
        description_standard: mods.record_info.descriptionStandard.map(&:text),
      }
    end

    def rights
      {
        restrictions: mods.xpath(
          '/mods:mods/mods:accessCondition[@type="use and reproduction"]',
          NAMESPACES
        ).map { |node| strip_whitespace(node.text) },

        rights_holder: rights_holder,
        copyright_status: mods.xpath(
          "//mods:extension/copyrightStatus/@valueURI",
          NAMESPACES
        ).map { |uri| RDF::URI.new(uri.value) },

        license: mods.xpath(
          "//mods:extension/copyrightStatement/@valueURI",
          NAMESPACES
        ).map { |uri| RDF::URI.new(uri.value) },
      }
    end

    def locations
      {
        location: mods.subject.geographic.valueURI.map do |uri|
          RDF::URI.new(uri)
        end,

        sub_location: mods.location.holdingSimple.xpath(
          "./mods:copyInformation/mods:subLocation",
          NAMESPACES
        ).map(&:text),

        institution: mods.location.physicalLocation.valueURI.map do |uri|
          RDF::URI.new(uri)
        end,

        place_of_publication: mods.origin_info.place.placeTerm.map(&:text),
      }.merge(coordinates)
    end

    def dates
      {
        issued_attributes: build_date(mods.origin_info.dateIssued),
        created_attributes: build_date(mods.origin_info.dateCreated),
        date_other_attributes: build_date(mods.origin_info.dateOther),
        date_copyrighted_attributes: build_date(mods.origin_info.copyrightDate),
        date_valid_attributes: build_date(mods.origin_info.dateValid),
      }
    end

    def identifiers
      { accession_number: mods.identifier.map(&:text) }
    end

    def finding_aid
      {
        finding_aid: mods.xpath(
          "//mods:url[@note='Finding aid']",
          NAMESPACES
        ).map { |url| RDF::URI.new(url.text) },
      }
    end

    def record_origin
      ro = []
      if mods.record_info && mods.record_info.respond_to?(:recordOrigin)
        ro += mods.record_info.recordOrigin.map do |node|
          prepend_timestamp(strip_whitespace(node.text))
        end
      end
      ro << prepend_timestamp(ORIGIN_TEXT)
    end

    # returns a hash with :latitude and :longitude
    def coordinates
      coords = mods.subject.cartographics.coordinates.map(&:text)
      # a hash where any value defaults to an empty array
      result = Hash.new { |h, k| h[k] = [] }
      coords.each_with_object(result) do |coord, obj|
        (latitude, longitude) = coord.split(/,\s*/)
        obj[:latitude] << latitude
        obj[:longitude] << longitude
      end
    end

    def mods_description
      mods.abstract.map { |e| strip_whitespace(e.text) }
    end

    def relations
      name_nodes = mods.xpath("//mods:mods/mods:name", NAMESPACES)
      property_name_for_uri = Marcrel.all.invert
      name_nodes.each_with_object({}) do |node, relations|
        uri = node.attributes["valueURI"]
        key = if (value_uri = node.role.roleTerm.valueURI.first)
                property_name_for_uri[RDF::URI(value_uri)]
              else
                $stderr.puts "no role was specified "\
                             "for name #{node.namePart.text}"
                :contributor
              end
        unless key
          key = :contributor
          $stderr.puts "the specified role for name #{node.namePart.text} "\
                       "is not a valid marcrelator role"
        end
        relations[key] ||= []
        val = if uri.blank?
                {
                  name: node.namePart.map { |o| o }.join(", "),
                  type: node.attributes["type"].value,
                }
              else
                RDF::URI.new(uri)
              end
        relations[key] << val
      end
    end

    def persistent_id(raw_id)
      return unless raw_id
      raw_id.downcase.gsub(/\s*/, "")
    end

    def collection
      {
        accession_number: human_readable_id,
        title: collection_name,
      }
    end

    def collection_name
      node_set = mods.at_xpath("//mods:relatedItem[@type='host']", NAMESPACES)
      return unless node_set
      [node_set.titleInfo.title.text.strip]
    end

    def human_readable_id
      node_set = mods.related_item.at_xpath('mods:identifier[@type="local"]',
                                            NAMESPACES)
      return [] unless node_set
      Array(node_set.text)
    end

    # Remove multiple whitespace
    def citation
      mods.xpath(
        '//mods:note[@type="preferred citation"]',
        NAMESPACES
      ).map { |node| node.text.gsub(/\n\s+/, "\n") }
    end

    def notes
      preferred_citation = "preferred citation"

      mods.note.map do |note|
        next if note.attributes.key?("type") &&
                note.attributes["type"].value == preferred_citation

        hash = { value: note.text.gsub(/\n\s+/, "\n") }
        type_attr = note.attributes["type"].try(:text)
        hash[:note_type] = type_attr if type_attr
        hash
      end.compact
    end

    private

      def build_date(node)
        finish = finish_point(node)
        start = start_point(node)
        dates = [
          {
            start: start.map(&:text),
            finish: finish.map(&:text),
            label: date_label(node),
            start_qualifier: qualifier(start),
            finish_qualifier: qualifier(finish),
          },
        ]
        dates.delete_if { |date| date.values.all?(&:blank?) }
        dates
      end

      def qualifier(nodes)
        nodes.map { |node| node.attributes["qualifier"].try(:value) }.compact
      end

      def finish_point(node)
        node.css('[point="end"]')
      end

      def start_point(node)
        node.css("[encoding]:not([point='end'])")
      end

      def date_label(node)
        node.css(":not([encoding])").map(&:text)
      end

      def untyped_title
        mods.xpath(
          "/mods:mods/mods:titleInfo[not(@type)]/mods:title",
          NAMESPACES
        ).map(&:text)
      end

      def alt_title
        Array(mods.xpath("//mods:titleInfo[@type]",
                         NAMESPACES)).flat_map do |node|

          type = node.attributes["type"].text
          alternative = "alternative"

          node.title.map do |title|
            value = title.text
            unless type == alternative
              Rails.logger.debug(
                "Transformation: \"#{type} title\" "\
                "will be stored as \"#{alternative} title\": #{value}"
              )
            end
            value
          end
        end
      end

      def rights_holder
        nodes = mods.extension.xpath("./copyrightHolder")
        nodes.map do |node|
          uri = node.attributes["valueURI"]
          text = node.text
          uri.blank? ? strip_whitespace(text) : RDF::URI.new(uri)
        end
      end

      def prepend_timestamp(text)
        "#{Time.now.utc.to_s(:iso8601)} #{text}"
      end

      def strip_whitespace(text)
        text.tr("\n", " ").delete("\t")
      end

      def subject
        # rubocop:disable Metrics/LineLength
        mods.xpath("//mods:subject/mods:name/@valueURI|//mods:subject/mods:topic/@valueURI", NAMESPACES).map do |uri|
          RDF::URI.new(uri)
        end
        # rubocop:enable Metrics/LineLength
      end
  end
end
