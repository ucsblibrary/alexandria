require 'importer'
require 'traject'

class ObjectFactoryWriter

  AUDIO_TYPES = [RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/aum'),
                 RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/aun')].freeze
  ETD_TYPES   = [RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')].freeze

  attr_reader :settings # The passed-in settings
  attr_reader :verbose

  def initialize(arg_settings)
    @settings = Traject::Indexer::Settings.new(arg_settings)
    @etd = @settings['etd']
    @verbose = @settings['verbose']
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
    from_traject = context.with_indifferent_access

    # Attributes are assembled by Traject's MARC parser
    attributes = defaults.merge(from_traject)

    contrib = Array(attributes.delete('contributors')).first
    attributes.merge!(contrib) unless contrib.blank?

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

    files = find_files_to_attach(attributes)
    attributes[:files] = attributes.delete('filename')
    build_object(attributes, files)
  end

  private

  # Extract the cylinder numbers from names like these:
  # ["Cylinder 12783", "Cylinder 0006"]
  # and then find the files that match those numbers.
  # We want to return an array of arrays, like this:
  # [
  #   ['/path/cusb-cyl12783a.wav', /path/cusb-cyl12783b.wav'],
  #   ['/path/cusb-cyl0006a.wav',  /path/cusb-cyl0006b.wav'],
  # ]
    def find_files_to_attach(attributes)
      return [@etd] if @etd
      return [] unless @settings[:files_dir]

      files = attributes[:filename].map do |name|
        cylinder_number = name.match('Cylinder\ (\d+)')[1]
        Dir.glob(File.join(@settings[:files_dir], "**", "cusb-cyl#{cylinder_number}*"))
      end
      print_file_names(files)
      files
    end

    def print_file_names(files)
      return unless verbose
      puts "Files to attach:"
      puts files.flatten.each { |f| puts f.inspect }
    end

    # Traject doesn't have a mechanism for supplying defaults to these fields
    def overwrite_fields
      @overwrite_fields ||= %w(language created_start fulltext_link)
    end

    # This ensures that if a field isn't in a MARC record, but it is in Fedora,
    # then it will be overwritten with blank.
    def defaults
      overwrite_fields.each_with_object(HashWithIndifferentAccess.new) { |k, h| h[k] = [] }
    end

    def build_object(attributes, metadata)
      work_type = attributes.fetch('work_type').first
      add_collection_attributes(work_type, attributes)
      factory(work_type).new(attributes, metadata).run
    end

    def add_collection_attributes(work_type, attributes)
      case work_type
      when *ETD_TYPES
        attributes[:collection] = { id: 'etds', title: ['Electronic Theses and Dissertations'], accession_number: ['etds'] }
      when *AUDIO_TYPES
        # Collection is handled by Importer::Cylinder class
      else
        raise ArgumentError, "Unknown work type #{work_type}"
      end
    end

    def factory(work_type)
      case work_type
      when *ETD_TYPES
        Importer::Factory.for('ETD'.freeze)
      when *AUDIO_TYPES
        Importer::Factory.for('AudioRecording'.freeze)
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
