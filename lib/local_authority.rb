# frozen_string_literal: true

module LocalAuthority
  # Map the type to the correct model.  Example:
  # <mods:name type="personal">
  # type="personal" should map to the Person model.
  CONTRIBUTOR_CLASSES = {
    "personal" => Person,
    "corporate" => Organization,
    "conference" => Group,
    "family" => Group,
    "person" => Person,
    "group" => Group,
    "organization" => Organization,
    "agent" => Agent,
  }.freeze

  TOPIC_CLASSES = {
    "topic" => Topic,
    "subject" => Topic,
  }.merge(CONTRIBUTOR_CLASSES).freeze

  LOCAL_NAME_MODELS = [
    Agent,
    Person,
    Group,
    Organization,
  ].freeze

  LOCAL_SUBJECT_MODELS = [Topic].freeze

  # All types of local authorities
  LOCAL_AUTHORITY_MODELS = (LOCAL_NAME_MODELS + LOCAL_SUBJECT_MODELS).freeze

  # @param [ActiveFedora::Base, SolrDocument] record
  # @param [Array] models
  def self.local_authority?(record, models = LOCAL_AUTHORITY_MODELS)
    klass = if record.is_a?(SolrDocument)
              Array(record["has_model_ssim"]).first.constantize
            else
              record.class
            end
    models.include?(klass)
  end

  # @param [ActiveFedora::Base, SolrDocument] record
  def self.local_name_authority?(record)
    local_authority?(record, LOCAL_NAME_MODELS)
  end

  # @param [ActiveFedora::Base, SolrDocument] record
  def self.local_subject_authority?(record)
    local_authority?(record, LOCAL_SUBJECT_MODELS)
  end

  # @param [ActiveTriples::Resource] item
  # @return [Boolean] true if the target is a local authority record
  def self.local_object?(item)
    item.respond_to?(:rdf_subject) &&
      item.rdf_subject.is_a?(RDF::URI) &&
      item.rdf_subject.start_with?(ActiveFedora.fedora.host) &&
      # TODO: `item.class.include?(LinkedVocabs::Controlled)` could
      # replace the last term
      (item.is_a?(ControlledVocabularies::Creator) ||
       item.is_a?(ControlledVocabularies::Subject))
  end

  # @param [#rdf_subject]
  # @return [ActiveFedora::Base]
  def self.rdf_to_fedora(item)
    ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(item.rdf_subject))
  end

  def self.find_or_create_contributors(fields, attrs)
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
  def self.find_or_create_rdf_attribute(thing, attrs)
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

  def self.contributors_for_field(attrs, field)
    attrs[field].map do |value|
      case value
      when RDF::URI, String
        value
      when Hash
        find_or_create_local_contributor(value)
      end
    end
  end

  def self.find_or_create_local_contributor(attrs)
    type = attrs.fetch(:type).downcase
    name = attrs.fetch(:name)
    klass = CONTRIBUTOR_CLASSES[type]
    contributor = klass.where(foaf_name_ssim: name).first ||
                  klass.create(foaf_name: name)

    RDF::URI.new(contributor.public_uri)
  end

  # @param [Hash, String] value
  # @return [RDF::URI]
  def self.find_or_create_local_rights_holder(value)
    if value.is_a?(Hash)
      klass = CONTRIBUTOR_CLASSES[value.fetch(:type).downcase]
      value = value.fetch(:name)
    end
    klass ||= Agent

    rights_holder = klass.exact_model.where(foaf_name_ssim: value).first
    rights_holder ||= klass.create(foaf_name: value)
    RDF::URI.new(rights_holder.public_uri)
  end

  # @param [Hash] value
  # @return [RDF::URI]
  def self.find_or_create_local_lc_subject(value)
    type = value.fetch(:type).downcase

    if CONTRIBUTOR_CLASSES.keys.include?(type)
      find_or_create_local_contributor(value)
    else
      klass = TOPIC_CLASSES[type]
      name = value.fetch(:name)
      subj = klass.where(label_ssim: name).first ||
             klass.create(label: Array(name))

      RDF::URI.new(subj.public_uri)
    end
  end

  # @param [String] value
  # @return [RDF::URI]
  def self.find_or_create_local_location(value)
    subj = Topic.where(label: value).first || Topic.create(label: [value])
    RDF::URI.new(subj.public_uri)
  end
end
