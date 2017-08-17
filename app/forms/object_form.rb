# frozen_string_literal: true

class ObjectForm
  include HydraEditor::Form

  self.terms = [
    :title,
    :alternative,
    :accession_number,
    :description,
    :series_name,
    :work_type,
    :form_of_work,
    :extent,
    :place_of_publication,
    :location,
    :lc_subject,
    :publisher,
    :contributor,
    :latitude,
    :longitude,
    :digital_origin,
    :institution,
    :sub_location,
    :restrictions,
    :created,
    :issued,
    :date_other,
    :date_copyrighted,
    :language,
    :description_standard,
    :copyright_status,
    :license,
    :rights_holder,
    :admin_policy_id,
  ]

  self.required_fields = [] # Required fields

  # ARK and record_origin are read-only values on the form.
  delegate :ark, :record_origin, to: :model

  NESTED_ASSOCIATIONS = [
    :created,
    :issued,
    :date_valid,
    :date_other,
    :date_copyrighted,
  ].freeze

  def initialize_fields
    # we're making a local copy of the attributes that we can modify.
    @attributes = model.attributes
    terms.each { |key| initialize_field(key) }
  end

  # Refactor this to call super when this PR is merged:
  # https://github.com/projecthydra-labs/hydra-editor/pull/60
  def initialize_field(key)
    # Don't initialize fields that use the SubjectManager
    return if [:lc_subject,
               :form_of_work,
               :rights_holder,
               :institution,
               :work_type,].include?(key)

    if key == :contributor
      self[key] = multiplex_contributors
    elsif (reflection = model_class.reflect_on_association(key))
      initialize_association(reflection, key)
    elsif (class_name = model_class.properties[key.to_s].class_name)
      # Initialize linked properties such as language
      self[key] += [class_name.new]
    elsif self.class.multiple?(key)
      # pull the values out of the ActiveTriples::Relation into an
      # ordinary array
      self[key] = self[key].map { |val| val }
    elsif self[key].blank?
      self[key] = ""
    end
  end

  def initialize_association(reflection, key)
    if reflection.collection?
      association = model.send(key)

      self[key] = if association.empty?
                    Array(association.build)
                  else
                    association
                  end
    else
      self[key] = model.send(key)

      if key == :admin_policy_id && !self[key]
        self[key] = AdminPolicy::PUBLIC_POLICY_ID
      end
    end
  end

  class Contributor
    attr_reader :predicate, :model
    # @param [Oregon::ControlledVocabulary::Creator, Agent] model
    def initialize(model, predicate = nil)
      @model = model
      @predicate = predicate
    end

    def rdf_subject
      @model.rdf_subject
    end

    def rdf_label
      @model.rdf_label
    end

    def node?
      @model.respond_to?(:node?) ? @model.node? : false
    end
  end

  def multiplex_contributors
    Metadata::RELATIONS.keys.flat_map do |relation_type|
      model[relation_type].map { |i| Contributor.new(i, relation_type) }
    end
  end

  def self.model_attributes(form_params)
    demultiplex_contributors(super)
  end

  # @param [ActionController::Parameters] attrs
  def self.demultiplex_contributors(attrs)
    attributes_collection = (attrs.delete(:contributor_attributes) || {})
      .to_h
      .sort_by do |i, _|
        i.to_i
      end.map { |_, attributes| attributes }

    return attrs if attributes_collection.empty?

    attributes_collection.each do |row|
      next unless row[:predicate]

      attr_key = "#{row.delete(:predicate)}_attributes"
      attrs[attr_key] ||= []
      attrs[attr_key] << row
    end

    attrs.to_h
  end

  def self.fedora_url_prefix
    active_fedora_config.fetch(:url) +
      active_fedora_config.fetch(:base_path) +
      "\/"
  end

  def self.active_fedora_config
    ActiveFedora.config.credentials
  end

  def self.permitted_time_span_params
    [:id,
     :_destroy,
     {
       start: [],
       start_qualifier: [],
       finish: [],
       finish_qualifier: [],
       label: [],
       note: [],
     },]
  end

  def self.build_permitted_params
    permitted = super
    permitted.delete(contributor: [])
    permitted.delete(location: [])
    permitted.delete(lc_subject: [])
    permitted.delete(form_of_work: [])
    permitted.delete(license: [])
    permitted.delete(copyright_status: [])
    permitted.delete(language: [])
    permitted.delete(rights_holder: [])
    permitted.delete(institution: [])

    permitted << { contributor_attributes: [:id, :predicate, :_destroy] }

    permitted << { location_attributes: [:id, :_destroy] }
    permitted << { lc_subject_attributes: [:id, :_destroy] }
    permitted << { work_type_attributes: [:id, :_destroy] }
    permitted << { form_of_work_attributes: [:id, :_destroy] }
    permitted << { license_attributes: [:id, :_destroy] }
    permitted << { copyright_status_attributes: [:id, :_destroy] }
    permitted << { language_attributes: [:id, :_destroy] }
    permitted << { rights_holder_attributes: [:id, :_destroy] }
    permitted << { institution_attributes: [:id, :_destroy] }

    # Time spans
    permitted << { created_attributes: permitted_time_span_params }
    permitted << { issued_attributes: permitted_time_span_params }
    permitted << { date_other_attributes: permitted_time_span_params }
    permitted << { date_valid_attributes: permitted_time_span_params }
    permitted << { date_copyrighted_attributes: permitted_time_span_params }
    permitted
  end
end
