require 'importer/log_subscriber'
module Importer::Factory
  class ObjectFactory
    attr_reader :attributes, :files_directory

    def initialize(attributes, files_dir = nil)
      @files_directory = files_dir
      @attributes = attributes
    end

    def run
      if obj = find
        ActiveSupport::Notifications.instrument('import.importer',
                                                id: attributes[:id], name: 'UPDATE', klass: klass) do
          update(obj)
        end
      else
        ActiveSupport::Notifications.instrument('import.importer',
                                                id: attributes[:id], name: 'CREATE', klass: klass) do
          obj = create
        end
      end
      yield(obj) if block_given?
      obj
    end

    def update(obj)
      obj.attributes = update_attributes
      obj.save!
      after_save(obj)
      log_updated(obj)
    end

    # override after_save if you want to put something here.
    def after_save(obj)
    end

    # override after_create if you want to put something here.
    def after_create(obj)
    end

    def create_attributes
      transform_attributes.except(:files)
    end

    def update_attributes
      transform_attributes.except(:id, :files)
    end

    def find
      klass.find(attributes[:id]) if klass.exists?(attributes[:id])
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
      klass.new(attrs) do |obj|
        obj.save!
        after_create(obj)
        after_save(obj)
        if identifier
          identifier.target = path_for(obj)
          identifier.save
        end
        log_created(obj)
      end
    end

    def log_created(obj)
      puts "  Created #{klass.to_s.downcase} #{obj.id} (#{attributes[:accession_number].first})"
    end

    def log_updated(obj)
      puts "  Updated #{klass.to_s.downcase} #{obj.id} (#{attributes[:accession_number].first})"
    end

    def klass
      fail 'You must implement the klass method'
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
          'organization' => Organization
        }
      end

      def topic_classes
        @topic_classes ||= {
          'topic' => Topic,
          'subject' => Topic
        }.merge(contributor_classes)
      end

      def transform_attributes
        contributors = find_or_create_contributors(klass.contributor_fields, attributes)
        rights_holders = find_or_create_rights_holders(attributes)
        subjects = find_or_create_subjects(attributes)

        attributes.merge(contributors)
                  .merge(rights_holders)
                  .merge(subjects)
      end

      def host
        Rails.application.config.host_name
      end

      def path_for(obj)
        "http://#{host}/lib/#{obj.ark}"
      end

  end
end
