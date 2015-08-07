require 'importer'
require 'traject'

class ObjectFactoryWriter

  # The passed-in settings
  attr_reader :settings

  def initialize(argSettings)
    @settings = Traject::Indexer::Settings.new(argSettings)
  end

  def serialize(context)
    # null
  end

  def close
    puts "closing"
    # null
  end

  # Add a single context to fedora
  def put(context)
    from_traject = context.output_hash.with_indifferent_access
    unknown_fields = from_traject.keys - expected_fields

    unless unknown_fields.blank?
      $stderr.puts "Skipping #{from_traject[:identifier]} : ERROR: Unknown field(s) #{unknown_fields}"
      return
    end

    attributes = defaults.merge(from_traject)

    relators = parse_relators(attributes.delete('names'), attributes.delete('relators'))

    if relators
      attributes.merge!(relators)
    else
      $stderr.puts "Skipping #{attributes[:identifier]} : ERROR: Names in field 720a don't match relators in field 720e"
      return
    end

    # created date is a TimeSpan
    created = attributes.delete('created_start')
    attributes[:created_attributes] = [{ start: created }] if created

    # title must be singular
    title = attributes.delete('title')
    attributes[:title] = title.first
    attributes[:id] = attributes.delete('id').first

    attributes[:files] = attributes.delete('filename')

    # TODO get a real collection properties
    attributes[:collection] = { id: "etds", title: "Electronic Theses and Dissertations", accession_number: ['etds'] }

    build_object(attributes)
  end

  private

    def expected_fields
      @expected ||= %w(identifier id system_number language created_start isbn
        title author place_of_publication publisher issued extent
        dissertation_degree dissertation_institution dissertation_year
        names relators description degree_grantor fulltext_link filename)
    end

    # This ensures that if a field isn't in a MARC record, but it is in Fedora,
    # then it will be overwritten with blank.
    def defaults
      expected_fields.each_with_object(HashWithIndifferentAccess.new) { |k, h| h[k] = [] }
    end

    def build_object(attributes)
      factory.new(attributes, Settings.proquest_directory).run
    end

    def factory
      Importer::Factory.for('ETD')
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
      ds = names.find_all.with_index { |_, index| relators[index].match(/degree supervisor/i) }
      fields[:degree_supervisor] = ds
      fields
    end

end
