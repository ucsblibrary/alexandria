module LocalAuthorityBase
  extend ActiveSupport::Concern

  included do
    belongs_to :admin_policy, class_name: "Hydra::AdminPolicy", predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
  end

  def to_solr(solr_doc={})
    super.tap do |solr_doc|
      solr_doc['uri_ssim'] = self.uri
    end
  end

  def initialize(attributes_or_id = nil, &block)
    super
    self.admin_policy_id = AdminPolicy::PUBLIC_POLICY_ID
  end

end
