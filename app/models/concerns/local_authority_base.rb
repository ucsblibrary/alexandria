module LocalAuthorityBase
  extend ActiveSupport::Concern

  included do
    belongs_to :admin_policy, class_name: 'Hydra::AdminPolicy', predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
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
    end
  end

  def initialize(attributes_or_id = nil, &block)
    super
    self.admin_policy_id = AdminPolicy::PUBLIC_POLICY_ID
  end
end
