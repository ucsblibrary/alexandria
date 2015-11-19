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
        attrs[:id] = Identifier.treeify(identifier.id.split(/\//).last)
      end

      # There's a bug in ActiveFedora when there are many
      # habtm <-> has_many associations, where they won't all get saved.
      # https://github.com/projecthydra/active_fedora/issues/874
      build_time_spans(attrs)
      build_notes(attrs)
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

    def build_time_spans(attrs)
      [:created, :date_other, :date_valid, :issued].each do |name|
        build_time_span(name, attrs)
      end
    end

    def build_time_span(name, attrs)
      build_nested(name, TimeSpan, attrs)
    end

    def build_nested(name, klass, attrs)
      collection_attrs = attrs.delete("#{name}_attributes".to_sym)
      return unless collection_attrs
      time_spans = collection_attrs.map do |ts_attrs|
        klass.create!(ts_attrs)
      end
      attrs.merge!("#{name.to_s.singularize}_ids" => time_spans.map(&:id))
    end

    def build_notes(attrs)
      build_nested('notes', Note, attrs)
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

    private

      def contributors_for_field(attrs, field)
        attrs[field].each_with_object([]) do |value, object|
          object << case value
                    when RDF::URI, String
                      value
                    when Hash
                      find_or_create_local_contributor(value.fetch(:type), value.fetch(:name))
          end
        end
      end

      def find_or_create_local_contributor(type, name)
        klass = contributor_classes[type]
        contributor = klass.where(foaf_name_ssim: name).first || klass.create(foaf_name: name)
        RDF::URI.new(contributor.uri)
      end

      def find_or_create_local_rights_holder(name)
        rights_holder = Agent.exact_model.where(foaf_name_ssim: name).first
        rights_holder ||= Agent.create(foaf_name: name)
        RDF::URI.new(rights_holder.uri)
      end

      def host
        Rails.application.config.host_name
      end

      def path_for(obj)
        "http://#{host}/lib/#{obj.ark}"
      end

      # Map the MODS name type to the correct model.
      # Example:
      # <mods:name type="personal">
      # A name with type="personal" should map to the Person model
      def contributor_classes
        @contributor_classes ||= {
          'personal' => Person,
          'corporate' => Organization,
          'conference' => Group,
          'family' => Group }
      end

      def transform_attributes
        contributors = find_or_create_contributors(klass.contributor_fields, attributes)
        rights_holders = find_or_create_rights_holders(attributes)
        attributes.merge(contributors).merge(rights_holders)
      end
  end
end
