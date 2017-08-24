# frozen_string_literal: true

require "importer"
require "traject"

class ObjectFactoryWriter
  AUDIO_TYPES = [
    RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/aum"),
    RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/aun"),
  ].freeze

  ETD_TYPES = [
    RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/txt"),
  ].freeze

  attr_reader :logger

  def initialize(arg_settings)
    @settings = Traject::Indexer::Settings.new(arg_settings)
    @etd = @settings["etd"]
    @local_collection_id = @settings["local_collection_id"]
    @logger = @settings["logger"]
  end

  def serialize(_context); end

  def close; end

  # Add a single context to fedora
  def put(context)
    relators = parse_relators(context.delete("names"),
                              context.delete("relators"))
    if relators.blank?
      logger.warn "Skipping #{context["identifier"]}: "\
                  "Names in field 720a don't match relators in field 720e"
      return
    end

    attributes = base_attributes(
      context.with_indifferent_access,
      relators
    ).with_indifferent_access

    build_object(
      attributes,
      find_files_to_attach(attributes)
    )
  end

  def base_attributes(traject_context, relators)
    # These defaults ensure that if a field isn't in a MARC record,
    # but it is in Fedora, then it will be overwritten with blank.
    {
      language: [],
      created_start: [],
      fulltext_link: (traject_context[:fulltext_link] || []),
    }.merge(traject_context)
      .merge(transform_traject_attrs(traject_context))
      .merge(etd_attributes)
      .merge(relators)
  end

  def transform_traject_attrs(attrs)
    if attrs["created_start"]
      { created_attributes: [{ start: attrs["created_start"] }] }
    else
      {}
    end.merge(
      # ID value must be singular
      id: attrs["id"].first
    ).merge(attrs["contributors"]&.first || {})
  end

  def etd_attributes
    if @etd.present?
      xml = Nokogiri::XML(File.read(@etd["xml"]))

      { rights_holder: Proquest::XML.rights_holder(xml),
        date_copyrighted: Proquest::XML.date_copyrighted(xml), }
    else
      {}
    end
  end

  # Extract the cylinder numbers from names like these:
  # ["Cylinder 12783", "Cylinder 0006"]
  # and then find the files that match those numbers.
  # We want to return an array of arrays, like this:
  # [
  #   ['/path/cusb-cyl12783a.wav', /path/cusb-cyl12783b.wav'],
  #   ['/path/cusb-cyl0006a.wav',  /path/cusb-cyl0006b.wav'],
  # ]
  def find_files_to_attach(attributes)
    return @etd if @etd
    return [] if @settings[:files_dirs].blank?

    file_groups = attributes[:fulltext_link].map do |name|
      match = name.match(/.*Cylinder(\d+)$/)
      next if match.blank?
      cylinder_number = match[1]

      @settings[:files_dirs].map do |dir| # Look in all the dirs
        Dir.glob(File.join(dir, "**", "cusb-cyl#{cylinder_number}*"))
      end.flatten
    end.reject(&:blank?)

    logger.debug "Files to attach:"
    file_groups.flatten.each { |f| logger.debug f.inspect }

    file_groups
  end

  private

    def build_object(metadata, data)
      metadata.delete("created_start")
      metadata.delete("contributors")
      metadata.delete("filename")

      work_type = metadata["work_type"].first

      if @local_collection_id.present?
        metadata[:local_collection_id] = [@local_collection_id]
      end

      factory(work_type).new(metadata, data, logger).run
    end

    def factory(work_type)
      case work_type
      when *ETD_TYPES
        Importer::Factory.for("ETD")
      when *AUDIO_TYPES
        Importer::Factory.for("AudioRecording")
      else
        raise ArgumentError, "Unknown work type #{work_type}"
      end
    end

    # @param [Array] names : a list of names
    # @param [Array] relators : a list of roles that correspond to those names
    # @return [Hash] relator fields
    # Example:
    #     name = ['Paul J. Atzberger', 'Frodo Baggins']
    #     relators = ['degree supervisor.', 'adventurer']
    # will return the thesis advisor:
    #     { degree_supervisor: ['Paul J. Atzberger'] }
    def parse_relators(names, relators)
      names = Array(names)
      relators = Array(relators)
      return nil unless names.count == relators.count

      fields = {}

      ds = names.find_all.with_index do |_, index|
        relators[index].match(/degree supervisor/i)
      end

      fields[:degree_supervisor] = ds
      fields
    end
end
