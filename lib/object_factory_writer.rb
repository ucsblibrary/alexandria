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
    puts 'closing'
    # null
  end

  # Add a single context to fedora
  def put(context)
    from_traject = context.output_hash.with_indifferent_access

    # Compact arrays to work around https://github.com/traject/traject/issues/113
    from_traject.each do |_, v|
      v.compact!
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

    # id must be singular
    attributes[:id] = attributes[:id].first

    attributes[:files] = attributes.delete('filename')

    build_object(attributes)
  end

  private

    # Traject doesn't have a mechanism for supplying defaults to these fields
    def overwrite_fields
      @overwrite_fields ||= %w(language created_start fulltext_link)
    end

    # This ensures that if a field isn't in a MARC record, but it is in Fedora,
    # then it will be overwritten with blank.
    def defaults
      overwrite_fields.each_with_object(HashWithIndifferentAccess.new) { |k, h| h[k] = [] }
    end

    def build_object(attributes)
      work_type = attributes.fetch('work_type').first
      attributes[:collection] = collection_attributes(work_type)

      factory(work_type).new(attributes, Settings.proquest_directory).run
    end

    def collection_attributes(work_type)
      case work_type
      when RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')
        { id: 'etds', title: ['Electronic Theses and Dissertations'], accession_number: ['etds'] }
      when RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/aum')
        { id: 'cylinders', title: ['Wax Cylinders'], accession_number: ['cylinders'], admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID }
      else
        raise ArgumentError, "Unknown work type #{work_type}"
      end
    end

    def factory(work_type)
      case work_type
      when RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')
        Importer::Factory.for('ETD')
      when RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/aum')
        Importer::Factory.for('AudioRecording')
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
      ds = names.find_all.with_index { |_, index| relators[index].match(/degree supervisor/i) }
      fields[:degree_supervisor] = ds
      fields
    end
end
