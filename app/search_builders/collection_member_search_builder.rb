class CollectionMemberSearchBuilder < Hydra::Collections::MemberSearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
end
