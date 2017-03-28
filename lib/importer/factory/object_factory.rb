# frozen_string_literal: true

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
        update
      else
        create
      end
      yield(object) if block_given?
      object
    end

    def update
      raise "Object doesn't exist" unless object

      %w(created issued notes).each do |prop|
        clear_attribute!(object, prop)
      end

      object.attributes = update_attributes

      # TODO: #attach_files needs to always run for ETD ingests, since
      # it triggers {Proquest::Metadata#run} which updates the
      # {AdminPolicy} of the ETD itself. Currently on ETD ingests,
      # `files' is never empty, so for now this is OK.
      if files.empty?
        $stderr.puts "No files provided for #{object.id}"
      else
        attach_files(object, files)
      end

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

    # Remove any existing FileSets via the FileSetActor Actor
    # This will also remove any derivatives etc that the FileSet created, and
    # it will remove it from membership in the given object.
    # @param [ActiveFedora::Base] object
    def remove_existing_file_sets(object)
      return unless object.file_sets && !object.file_sets.empty?
      object.file_sets.each do |f|
        CurationConcerns::Actors::FileSetActor.new(f, nil).destroy
      end
      object.save
      object.reload.file_sets
    end

    # Overridden in classes that inherit from ObjectFactory
    #
    # @param [Hash] object
    # @param [String, Hash] files Either the path to the file or a hash with file metadata
    def attach_files(_object, _files)
      raise NotImplementedError, "#attach_files is not defined for #{self.class}"
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
        identifier = Ezid::Identifier.mint(
          profile: :erc,
          erc_what: attrs[:title].first
        )
        attrs[:identifier] = [identifier.id]
        attrs[:id] = identifier.id.split("/").last
      end

      # There's a bug in ActiveFedora when there are many
      # habtm <-> has_many associations, where they won't all get saved.
      # https://github.com/projecthydra/active_fedora/issues/874
      #
      # TODO: what does the above comment mean, and how does it relate to this code

      @object = klass.new(attrs)

      # TODO: #attach_files needs to always run for ETD ingests, since
      # it triggers {Proquest::Metadata#run} which updates the
      # {AdminPolicy} of the ETD itself. Currently on ETD ingests,
      # `files' is never empty, so for now this is OK.
      if files.empty?
        $stderr.puts "No files provided for #{object.id}"
      else
        attach_files(object, files)
      end

      run_callbacks :save do
        run_callbacks :create do
          object.save!
        end
      end
      # The fields used for erc_when and erc_who are set during the
      # object creation, so we have to update the ARK metadata
      # afterwards
      if identifier
        identifier[:target] = path_for(object)
        # Arrays of TimeSpans
        erc_date = object.created.first || object.issued.first
        date_arr = erc_date.to_a
        # Some TimeSpan arrays aren't arrays, what a world
        identifier[:erc_when] = if date_arr.respond_to?(:first)
                                  # if the array has multiple
                                  # elements, format it as a range
                                  # for Ezid
                                  if date_arr.length > 1
                                    "#{date_arr.first}-#{date_arr.last}"
                                  else
                                    date_arr.first
                                  end
                                else
                                  date_arr
                                end

        # Use the combination of all authorial roles
        contributors = object.to_solr[ContributorIndexer::ALL_CONTRIBUTORS_LABEL]
        unless contributors.blank?
          identifier[:erc_who] = contributors.join("; ")
        end

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

      def clear_attribute!(obj, attr)
        obj[attr] = []
        obj.send("#{attr}_will_change!")
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
          ""
        end
      end

      # Map the type to the correct model.  Example:
      # <mods:name type="personal">
      # type="personal" should map to the Person model.
      def contributor_classes
        @contributor_classes ||= {
          "personal" => Person,
          "corporate" => Organization,
          "conference" => Group,
          "family" => Group,
          "person" => Person,
          "group" => Group,
          "organization" => Organization,
          "agent" => Agent,
        }
      end

      def topic_classes
        @topic_classes ||= {
          "topic" => Topic,
          "subject" => Topic,
        }.merge(contributor_classes)
      end

      def transform_attributes
        contributors = find_or_create_contributors(klass.contributor_fields, attributes)
        notes = extract_notes(attributes)
        rights_holders = find_or_create_rdf_attribute(:rights_holder, attributes)
        subjects = find_or_create_rdf_attribute(:lc_subject, attributes)
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
        values = if attributes[:notes_attributes]
                   attributes.delete(:notes_attributes)
                 else
                   # :note will be an array if it exists, but if it doesn't it
                   # will return nil, which is why we need to wrap the thing in
                   # another array then flatten and compact
                   [attributes.delete(:note)].flatten.compact.map do |n|
                     if n.is_a? Hash
                       { note_type: n[:type], value: n[:name] }
                     else
                       { note_type: nil, value: n }
                     end
                   end
                 end
        { notes_attributes: values }
      end

      def host
        Rails.application.config.host_name
      end

      def path_for(obj)
        # FIXME: will change with TLS
        "http://#{host}/lib/#{obj.ark}"
      end
  end
end
