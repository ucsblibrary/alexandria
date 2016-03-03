require 'importer/log_subscriber'
module Importer::Factory
  class ObjectFactory
    extend ActiveModel::Callbacks
    define_model_callbacks :save, :create
    after_save :attach_files

    class_attribute :klass, :attach_files_service, :system_identifier_field

    attr_reader :attributes, :files_directory, :object

    def initialize(attributes, files_dir = nil)
      @files_directory = files_dir
      @attributes = attributes
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

    def attach_files
      return unless files_directory.present? && attributes[:files]

      attach_files_service.run(object, files_directory, attributes[:files])
      object.save! # Save the association with the attached files.
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
      puts "  Created #{klass.model_name.human} #{obj.id} (#{Array(attributes[system_identifier_field]).first})"
    end

    def log_updated(obj)
      puts "  Updated #{klass.model_name.human} #{obj.id} (#{Array(attributes[system_identifier_field]).first})"
    end

    # @return [Ezid::Identifier] the new identifier
    def mint_ark
      Ezid::Identifier.create
    end

    def find_or_create_contributors(fields, attrs)
      {}.tap do |contributors|
        fields.each do |field|
          next unless attrs.key?(field)
          contributors[field] = contributors_for_field(attrs, field)
        end
      end
    end

    def find_or_create_rights_holders(attrs)
      rights_holders = attrs.fetch(:rights_holder, []).map do |value|
        if value.is_a?(RDF::URI)
          value
        else
          find_or_create_local_rights_holder(value)
        end
      end

      rights_holders.blank? ? {} : { rights_holder: rights_holders }
    end

    def find_or_create_subjects(attrs)
      subs = attrs.fetch(:lc_subject, []).map do |value|
        if value.is_a?(RDF::URI)
          value
        else
          find_or_create_local_subject(value)
        end
      end
      subs.blank? ? {} : { lc_subject: subs }
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
        RDF::URI(contributor.public_uri)
      end

      def find_or_create_local_rights_holder(name)
        if name.is_a?(Hash)
          klass = contributor_classes[name.fetch(:type).downcase]
          name = name.fetch(:name)
        end
        klass ||= Agent

        rights_holder = klass.exact_model.where(foaf_name_ssim: name).first
        rights_holder ||= klass.create(foaf_name: name)
        RDF::URI.new(rights_holder.public_uri)
      end

      def find_or_create_local_subject(subj_hash)
        type = subj_hash.fetch(:type).downcase

        if contributor_classes.keys.include?(type)
          find_or_create_local_contributor(subj_hash)
        else
          klass = topic_classes[type]
          name = subj_hash.fetch(:name)
          subj = klass.where(label_ssim: name).first || klass.create(label: Array(name))
          RDF::URI.new(subj.public_uri)
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
        rights_holders = find_or_create_rights_holders(attributes)
        subjects = find_or_create_subjects(attributes)
        notes = extract_notes(attributes)

        attributes.merge(contributors)
                  .merge(rights_holders)
                  .merge(subjects)
                  .merge(notes)
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
