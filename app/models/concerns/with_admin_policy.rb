module WithAdminPolicy
  extend ActiveSupport::Concern

  included do
    belongs_to :admin_policy, class_name: 'Hydra::AdminPolicy', predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
  end
end
