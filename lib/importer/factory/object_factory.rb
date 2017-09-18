# frozen_string_literal: true

require "local_authority"

module Importer::Factory
  class ObjectFactory
    extend ActiveModel::Callbacks
    define_model_callbacks :save, :create
    class_attribute :klass, :system_identifier_field

    attr_reader :attributes, :files, :object, :logger

    def initialize(attributes, files = [], logger = Logger.new(STDOUT))
      @attributes = attributes
      @files = files
      @logger = logger
    end

    def run
      if (@object = find)
        update
      else
        create
      end
      yield(object) if block_given?
      object
    end

    def find
      if attributes[:id]
        klass.find(attributes[:id]) if klass.exists?(attributes[:id])
      elsif attributes[system_identifier_field].present?
        klass.where(
          # TODO: replace with literal field name
          Solrizer.solr_name(
            system_identifier_field, :symbol
          ) => attributes[system_identifier_field]
        ).first
      else
        raise "Missing identifier: Unable to search for existing object "\
              "without either fedora ID or #{system_identifier_field}"
      end
    end

    def create
      attrs = create_attributes
      identifier = mint_ark_if_new!(attrs.with_indifferent_access)

      @object = klass.new(
        attrs.merge(
          if identifier.present?
            { identifier: [identifier.id],
              id: identifier.id.split("/").last, }
          else
            {}
          end
        )
      )

      # TODO: #attach_files needs to always run for ETD ingests, since
      # it triggers {Proquest::Metadata#run} which updates the
      # {AdminPolicy} of the ETD itself. Currently on ETD ingests,
      # `files' is never empty, so for now this is OK.
      if files.empty?
        logger.debug "No files provided for #{object.id}"
      else
        attach_files(object, files)
        render_thumbnails(object)
      end

      run_callbacks :save do
        run_callbacks :create do
          object.save!
        end
      end

      # The fields used for erc_when and erc_who are set during the
      # object creation, so we have to update the ARK metadata
      # afterwards
      hydrate_ark!(identifier) if identifier.present?

      logger.info "Created #{klass.model_name.human} #{object.id} "\
                  "(#{Array(attributes[system_identifier_field]).first})"
    end

    def update
      raise "Object doesn't exist" unless object

      %w[created issued notes].each do |prop|
        clear_attribute!(object, prop)
      end

      object.attributes = update_attributes

      # TODO: #attach_files needs to always run for ETD ingests, since
      # it triggers {Proquest::Metadata#run} which updates the
      # {AdminPolicy} of the ETD itself. Currently on ETD ingests,
      # `files' is never empty, so for now this is OK.
      if files.empty?
        logger.debug "No files provided for #{object.id}"
      else
        attach_files(object, files)
        render_thumbnails(object)
      end

      run_callbacks(:save) do
        object.save!
      end

      logger.info "Updated #{klass.model_name.human} #{object.id} "\
                  "(#{Array(attributes[system_identifier_field]).first})"
    end

    # Overridden in classes that inherit from ObjectFactory
    #
    # @param [Hash] object
    # @param [String, Hash] files Either the path to the file or a
    #     hash with file metadata
    def attach_files(_object, _files)
      raise NotImplementedError,
            "#attach_files is not defined for #{self.class}"
    end

    def render_thumbnails(object)
      unless [Image, ComponentMap, IndexMap, ScannedMap].include?(object.class)
        return
      end

      object.file_sets.map(&:files).flatten.each do |f|
        Settings.thumbnails.keys.each do |k|
          options = {
            size: Settings.thumbnails[k]["size"],
            rotation: "0",
            region: Settings.thumbnails[k].fetch("region", "full"),
            quality: "default",
            format: "jpg",
          }.with_indifferent_access

          Riiif::Image.new(f.id).render(options)
        end
      end
    ensure
      FileUtils.rm_rf Settings.riiif_fedora_cache
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
      return if object.file_sets.blank?
      object.file_sets.each do |f|
        CurationConcerns::Actors::FileSetActor.new(f, nil).destroy
      end
      object.save
      object.reload.file_sets
    end

    # @param [Hash] attrs
    # @return [Nil, Ezid::Identifier]
    def mint_ark_if_new!(attrs)
      # Don't mint arks for records that already have them (e.g. ETDs)
      return if attrs[:identifier].present?

      Ezid::Identifier.mint(
        profile: :erc,
        erc_what: attrs[:title].first
      )
    end

    def hydrate_ark!(identifier)
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
      contributors = object.to_solr[ObjectIndexer::ALL_CONTRIBUTORS_LABEL]
      identifier[:erc_who] = contributors.join("; ") if contributors.present?

      identifier.save
    end

    private

      def clear_attribute!(obj, attr)
        obj[attr] = []
        obj.send("#{attr}_will_change!")
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

      def transform_attributes
        contributors = LocalAuthority.find_or_create_contributors(
          klass.contributor_fields,
          attributes
        )
        rights_holders = LocalAuthority.find_or_create_rdf_attribute(
          :rights_holder, attributes
        )
        subjects = LocalAuthority.find_or_create_rdf_attribute(
          :lc_subject,
          attributes
        )
        locations = LocalAuthority.find_or_create_rdf_attribute(
          :location,
          attributes
        )

        notes = extract_notes(attributes)
        description = {
          description: [join_paragraphs(attributes[:description])],
        }
        restrictions = {
          restrictions: [join_paragraphs(attributes[:restrictions])],
        }

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
