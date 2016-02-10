module LocalAuthorityBase
  extend ActiveSupport::Concern

  included do
    belongs_to :admin_policy, class_name: 'Hydra::AdminPolicy', predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy

    # This allows us to scope queries directly against a
    # specific subclass.  Otherwise, "Agent.all" would return
    # instances of any subclass of Agent (e.g. Person).
    def self.exact_model
      where(has_model_ssim: to_s)
    end
  end

  # This asserts that this record is valid for a vocab. This works around
  # the LinkedVocabs::Validators::PropertyValidator
  # This is correct as long as all our properties allow the local vocabulary
  # and that we  put all our local objects into a single namespace
  # (e.g. don't segregate People from Topics)
  # Otherwise we could set Topic#rdf_subject
  def in_vocab?
    true
  end

  def to_solr(solr_doc = {})
    super.tap do |solr_doc|
      solr_doc['uri_ssim'] = uri
      solr_doc['public_uri_ssim'] = public_uri
    end
  end

  def public_uri
    return nil if new_record?
    routes = Rails.application.routes.url_helpers
    builder = ActionDispatch::Routing::PolymorphicRoutes::HelperMethodBuilder
    builder.polymorphic_method routes, self, nil, :url, host: Rails.application.config.host_name
  end

  def initialize(attributes_or_id = nil, &block)
    super
    self.admin_policy_id = AdminPolicy::PUBLIC_POLICY_ID
  end

  # When a collection of these are rendered, which partial should be used
  def to_partial_path
    'catalog/document'
  end
end
