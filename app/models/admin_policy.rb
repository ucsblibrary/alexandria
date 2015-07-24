module AdminPolicy

  ADMIN_USER_POLICY_ID    = 'authorities/policies/admin'.freeze
  DISCOVERY_POLICY_ID     = 'authorities/policies/discovery'.freeze
  UCSB_CAMPUS_POLICY_ID   = 'authorities/policies/ucsb_on_campus'.freeze
  UCSB_POLICY_ID          = 'authorities/policies/ucsb'.freeze
  PUBLIC_CAMPUS_POLICY_ID = 'authorities/policies/public_on_campus'.freeze
  PUBLIC_POLICY_ID        = 'authorities/policies/public'.freeze

  def self.ensure_admin_policy_exists

    # TODO: Should ADMIN_USER_POLICY_ID be changed to something like RESTRICTED_POLICY_ID ?
    unless Hydra::AdminPolicy.exists?(ADMIN_USER_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: ADMIN_USER_POLICY_ID, title: ['Admin users only'])
      policy.default_permissions.build(type: "group", name: "metadata_admin", access: "edit")
      policy.save!
    end

    unless Hydra::AdminPolicy.exists?(DISCOVERY_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: DISCOVERY_POLICY_ID, title: ['Discovery access only'])
      policy.default_permissions.build([ { type: "group", name: "metadata_admin", access: "edit" },
                                         { type: "group", name: "UCSB", access: "discover" },
                                         { type: "group", name: "public", access: "discover" } ])
      policy.save!
    end

    # TODO: Is this policy actually needed?
    unless Hydra::AdminPolicy.exists?(UCSB_CAMPUS_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: UCSB_CAMPUS_POLICY_ID, title: ['Campus use only, requires UCSB login'])
      policy.default_permissions.build([ { type: "group", name: "metadata_admin", access: "edit" },
                                         { type: "group", name: "ucsb-on-campus", access: "read" } ])
      policy.save!
    end

    unless Hydra::AdminPolicy.exists?(UCSB_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: UCSB_POLICY_ID, title: ['UCSB users only'])
      policy.default_permissions.build([ { type: "group", name: "metadata_admin", access: "edit" },
                                         { type: "group", name: "UCSB", access: "read" } ])
      policy.save!
    end

    unless Hydra::AdminPolicy.exists?(PUBLIC_CAMPUS_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: PUBLIC_CAMPUS_POLICY_ID, title: ['Campus use only'])
      policy.default_permissions.build([ { type: "group", name: "metadata_admin", access: "edit" },
                                         { type: "group", name: "UCSB", access: "read" },
                                         { type: "group", name: "public-on-campus", access: "read" } ])
      policy.save!
    end

    unless Hydra::AdminPolicy.exists?(PUBLIC_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: PUBLIC_POLICY_ID, title: ['Public access'])
      policy.default_permissions.build([ { type: "group", name: "metadata_admin", access: "edit" },
                                         { type: "group", name: "UCSB", access: "read" },
                                         { type: "group", name: "public", access: "read" } ])
      policy.save!
    end

  end
end
