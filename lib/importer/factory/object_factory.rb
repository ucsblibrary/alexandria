require 'importer/log_subscriber'

module Importer::Factory
  class ObjectFactory
    extend ActiveModel::Callbacks
    define_model_callbacks :save, :create
    class_attribute :klass, :system_identifier_field

    attr_reader :attributes, :files, :object

    def initialize(attributes, files = [])
      @attributes = attributes
      @files = files
    end

    def run
      if @object = find
        ActiveSupport::Notifications.instrument('import.importer',
                                                id: attributes[:id], name: 'UPDATE', klass: klass) do
          update
        end
      else
        ActiveSupport::Notifications.instrument('import.importer',
                                                id: attributes[:id], name: 'CREATE', klass: klass) do
          create
        end
      end
      yield(object) if block_given?
      object
    end

    def update
      raise "Object doesn't exist" unless object
      update_created_date(object)
      update_issued_date(object)
      update_notes(object)
      object.attributes = update_attributes
      attach_files(object, @files) unless @files.empty?
      run_callbacks(:save) do
        object.save!
      end
      log_updated(object)
    end

    def create_attributes
      transform_attributes.except(:files)
    end

    def update_attributes
      transform_attributes.except(:id, :files)
    end

    # Overridden in classes that inherit from ObjectFactory
    #
    # @param [Hash] object
    # @param [String, Hash] files Either the path to the file or a hash with file metadata
    def attach_files(object, files)
    end

    def find
      if attributes[:id]
        klass.find(attributes[:id]) if klass.exists?(attributes[:id])
      elsif !attributes[system_identifier_field].blank?
        klass.where(Solrizer.solr_name(system_identifier_field, :symbol) => attributes[system_identifier_field]).first
      else
        raise "Missing identifier: Unable to search for existing object without either fedora ID or #{system_identifier_field}"
      end
    end

    def create
      attrs = create_attributes
      # Don't mint arks for records that already have them (e.g. ETDs)
      unless attrs[:identifier].present?
        identifier = mint_ark
        attrs[:identifier] = [identifier.id]
        attrs[:id] = identifier.id.split(/\//).last
      end

      # There's a bug in ActiveFedora when there are many
      # habtm <-> has_many associations, where they won't all get saved.
      # https://github.com/projecthydra/active_fedora/issues/874
      @object = klass.new(attrs)
      attach_files(@object, @files) unless @files.empty?
      run_callbacks :save do
        run_callbacks :create do
          object.save!
        end
      end
      if identifier
        identifier.target = path_for(object)
        identifier.save
      end
      log_created(object)
    end

    def log_created(obj)
      Rails.logger.debug "Created #{klass.model_name.human} #{obj.id} (#{Array(attributes[system_identifier_field]).first})"
    end

    def log_updated(obj)
      Rails.logger.debug "Updated #{klass.model_name.human} #{obj.id} (#{Array(attributes[system_identifier_field]).first})"
    end

    # @return [Ezid::Identifier] the new identifier
    def mint_ark
      Ezid::Identifier.create
    end

    # TODO: refactor into `find_or_create_rdf_attribute'
    def find_or_create_contributors(fields, attrs)
      {}.tap do |contributors|
        fields.each do |field|
          next unless attrs.key?(field)
          contributors[field] = contributors_for_field(attrs, field)
        end
      end
    end

    # @param [Symbol] thing :rights_holder, :lc_subject
    # @param [Hash] attrs
    # @return [Hash]
    def find_or_create_rdf_attribute(thing, attrs)
      values = attrs.fetch(thing, []).map do |value|
        if value.is_a?(RDF::URI)
          value
        else
          case thing
          when :lc_subject
            find_or_create_local_lc_subject(value)
          when :location
            find_or_create_local_location(value)
          when :rights_holder
            find_or_create_local_rights_holder(value)
          end
        end
      end
      values.empty? ? {} : { thing => values }
    end

    private

      def update_created_date(obj)
        created_attributes = attributes.delete(:created_attributes)
        return if created_attributes.blank?

        new_date = created_attributes.first.fetch(:start, nil)
        return unless new_date

        existing_date = obj.created.flat_map(&:start)

        if existing_date != new_date
          # Create or update the existing date.
          if time_span = obj.created.to_a.first
            time_span.attributes = created_attributes.first
          else
            obj.created.build(created_attributes.first)
          end
          obj.created_will_change!
        end
      end

      def update_issued_date(obj)
        issued_attributes = attributes.delete(:issued_attributes)
        return if issued_attributes.blank?

        new_date = issued_attributes.first.fetch(:start, nil)
        return unless new_date

        existing_date = obj.issued.flat_map(&:start)

        if existing_date != new_date
          # Create or update the existing date.
          if time_span = obj.issued.to_a.first
            time_span.attributes = issued_attributes.first
          else
            obj.issued.build(issued_attributes.first)
          end
          obj.issued_will_change!
        end
      end

      def update_notes(obj)
        new_notes = Array(attributes.delete(:note))
        count = [new_notes.count, obj.notes.count].max

        for i in 0..(count - 1) do
          new_attrs = if new_notes[i].is_a?(Hash)
                        { note_type: new_notes[i][:type],
                          value: new_notes[i][:name] }
                      else
                        { note_type: [''],
                          value: new_notes[i] || [''] }
                      end

          existing_note = obj.notes[i]
          if existing_note
            existing_note.attributes = new_attrs
          else
            obj.notes.build(new_attrs)
          end
        end

        obj.notes_will_change!
      end

      def contributors_for_field(attrs, field)
        attrs[field].each_with_object([]) do |value, object|
          object << case value
                    when RDF::URI, String
                      value
                    when Hash
                      find_or_create_local_contributor(value)
                    end
        end
      end

      def find_or_create_local_contributor(attrs)
        type = attrs.fetch(:type).downcase
        name = attrs.fetch(:name)
        klass = contributor_classes[type]
        contributor = klass.where(foaf_name_ssim: name).first || klass.create(foaf_name: name)
        RDF::URI.new(contributor.public_uri)
      end

      # @param [Hash, String] value
      # @return [RDF::URI]
      def find_or_create_local_rights_holder(value)
        if value.is_a?(Hash)
          klass = contributor_classes[value.fetch(:type).downcase]
          value = value.fetch(:name)
        end
        klass ||= Agent

        rights_holder = klass.exact_model.where(foaf_name_ssim: value).first
        rights_holder ||= klass.create(foaf_name: value)
        RDF::URI.new(rights_holder.public_uri)
      end

      # @param [Hash] value
      # @return [RDF::URI]
      def find_or_create_local_lc_subject(value)
        type = value.fetch(:type).downcase

        if contributor_classes.keys.include?(type)
          find_or_create_local_contributor(value)
        else
          klass = topic_classes[type]
          name = value.fetch(:name)
          subj = klass.where(label_ssim: name).first || klass.create(label: Array(name))
          RDF::URI.new(subj.public_uri)
        end
      end

      # @param [String] value
      # @return [RDF::URI]
      def find_or_create_local_location(value)
        subj = Topic.where(label: value).first || Topic.create(label: [value])
        RDF::URI.new(subj.public_uri)
      end

      # Since arrays of RDF elements are not saved in order in Fedora,
      # we join each element (each paragraph) into a single string
      #
      # @param [Hash] field
      def join_paragraphs(field)
        if field
          field.join('\n\n')
        else
          ''
        end
      end

      # Map the type to the correct model.  Example:
      # <mods:name type="personal">
      # type="personal" should map to the Person model.
      def contributor_classes
        @contributor_classes ||= {
          'personal' => Person,
          'corporate' => Organization,
          'conference' => Group,
          'family' => Group,
          'person' => Person,
          'group' => Group,
          'organization' => Organization,
          'agent' => Agent,
        }
      end

      def topic_classes
        @topic_classes ||= {
          'topic' => Topic,
          'subject' => Topic,
        }.merge(contributor_classes)
      end

      def transform_attributes
        contributors = find_or_create_contributors(klass.contributor_fields, attributes)
        notes = extract_notes(attributes)
        rights_holders = find_or_create_rdf_attribute(:rights_holder, attributes)
        subjects = find_or_create_rdf_attribute(:lc_subjects, attributes)
        locations = find_or_create_rdf_attribute(:location, attributes)

        description = { description: [join_paragraphs(attributes[:description])] }
        restrictions = { restrictions: [join_paragraphs(attributes[:restrictions])] }

        attributes.merge(contributors)
                  .merge(description)
                  .merge(locations)
                  .merge(notes)
                  .merge(restrictions)
                  .merge(rights_holders)
                  .merge(subjects)
      end

      def extract_notes(attributes)
        notes = Array(attributes.delete(:note))
        notes = notes.map do |n|
          if n.is_a? Hash
            { note_type: n[:type], value: n[:name] }
          else
            { note_type: nil, value: n }
          end
        end
        { notes_attributes: notes }
      end

      def host
        Rails.application.config.host_name
      end

      def path_for(obj)
        "http://#{host}/lib/#{obj.ark}"
      end
  end
end
