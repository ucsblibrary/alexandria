module LocalAuthorityBase
  extend ActiveSupport::Concern

  included do
    belongs_to :admin_policy, class_name: "Hydra::AdminPolicy", predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy do |index|
      index_as :symbol
    end
  end

  def initialize(attributes_or_id = nil, &block)
    super
    self.admin_policy_id = AdminPolicy::PUBLIC_POLICY_ID
  end

end
