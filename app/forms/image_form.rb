class ImageForm
  include HydraEditor::Form
  self.model_class = Image

  self.terms = [:title, :alternative, :accession_number, :description,
                :series_name, :work_type, :form_of_work, :extent,
                :place_of_publication, :location, :lc_subject, :publisher,
                :contributor, :latitude, :longitude, :digital_origin, :institution,
                :sub_location, :restrictions, :created, :issued,
                :date_other, :date_copyrighted, :language, :description_standard,
                :copyright_status, :license, :rights_holder, :admin_policy_id]

  self.required_fields = [] # Required fields

  # ARK is a read only value on the form.
  def ark
    model.ark
  end

  # record_origin is a read only value on the form.
  def record_origin
    model.record_origin
  end

  NESTED_ASSOCIATIONS = [:created, :issued, :date_valid, :date_other, :date_copyrighted]

  protected

    def initialize_fields
      # we're making a local copy of the attributes that we can modify.
      @attributes = model.attributes
      terms.each { |key| initialize_field(key) }
    end

    # Refactor this to call super when this PR is merged: https://github.com/projecthydra-labs/hydra-editor/pull/60
    def initialize_field(key)
      # Don't initialize fields that use the SubjectManager
      return if [:lc_subject, :form_of_work, :rights_holder, :institution].include?(key)

      if key == :contributor
        self[key] = multiplex_contributors
      elsif reflection = model_class.reflect_on_association(key)
        initialize_association(reflection, key)
      elsif class_name = model_class.properties[key.to_s].class_name
        # TODO: I suspect this is dead code
        self[key] += [class_name.new]
      elsif self.class.multiple?(key)
        self[key] = Array.wrap(self[key]) + ['']
      elsif self[key].blank?
        self[key] = ''
      end
    end

    def initialize_association(reflection, key)
      if reflection.collection?
        association = model.send(key)

        if association.empty?
          self[key] = Array(association.build)
        else
          self[key] = association
        end
      else
        self[key] = model.send(key)
        self[key] = AdminPolicy::PUBLIC_POLICY_ID if key == :admin_policy_id && !self[key]
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

    def self.demultiplex_contributors(attrs)
      attributes_collection = attrs[:contributor_attributes]
      return attrs unless attributes_collection

      if attributes_collection.is_a? Hash
        attributes_collection =
          attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
      end
      attrs.except(:contributor_attributes).merge(
        attributes_collection.each_with_object({}.with_indifferent_access) do |row, relations|
          next unless row[:predicate]
          attr_key = "#{row.delete(:predicate)}_attributes"
          relations[attr_key] ||= []
          relations[attr_key] << row.with_indifferent_access
        end
      )
    end

    def self.fedora_url_prefix
      "#{active_fedora_config.fetch(:url)}#{active_fedora_config.fetch(:base_path)}\/"
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
       },
      ]
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
