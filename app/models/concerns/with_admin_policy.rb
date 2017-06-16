# frozen_string_literal: true

module WithAdminPolicy
  extend ActiveSupport::Concern

  included do
    belongs_to :admin_policy,
               class_name: "Hydra::AdminPolicy",
               predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
  end

  # Copy the policy of the parent work to its attached files
  def copy_admin_policy_to_files!
    return unless respond_to?(:file_sets)
    file_sets.each do |fs|
      fs.admin_policy_id = admin_policy_id
      fs.save!
    end
  end
end
