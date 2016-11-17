# frozen_string_literal: true

module AdminPolicy
  # A fedora object can have one of these policies
  RESTRICTED_POLICY_ID    = "authorities/policies/restricted"
  DISCOVERY_POLICY_ID     = "authorities/policies/discovery"
  UCSB_CAMPUS_POLICY_ID   = "authorities/policies/ucsb_on_campus"
  UCSB_POLICY_ID          = "authorities/policies/ucsb"
  UC_POLICY_ID            = "authorities/policies/uc"
  PUBLIC_CAMPUS_POLICY_ID = "authorities/policies/public_on_campus"
  PUBLIC_POLICY_ID        = "authorities/policies/public"

  # LDAP groups that a user might belong to
  META_ADMIN   = "METADATA_ADMIN"
  RIGHTS_ADMIN = "RIGHTS_ADMIN"

  # Groups assigned to a user dynamically by the app
  PUBLIC_CAMPUS_GROUP = "public_on_campus"
  PUBLIC_GROUP        = "public"
  UCSB_CAMPUS_GROUP   = "ucsb_on_campus"
  UCSB_GROUP          = "ucsb"
  UC_GROUP            = "any_uc"

  # @return [Hash]
  def self.all
    Rails.cache.fetch("admin_policies", expires_in: 1.year) do
      Rails.logger.warn "The admin policy cache is rebuilding"
      AdminPolicy.ensure_admin_policy_exists
      Hydra::AdminPolicy.all.each_with_object({}) do |ap, h|
        h[ap.id] = ap.title
      end
    end
  end

  def self.options_for_select
    all.invert
  end

  def self.find(id)
    all[id]
  end

  def self.ensure_admin_policy_exists
    unless Hydra::AdminPolicy.exists?(RESTRICTED_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: RESTRICTED_POLICY_ID, title: ["Restricted access"])
      policy.default_permissions.build([
                                         { type: "group", name: META_ADMIN, access: "edit" },
                                         { type: "group", name: RIGHTS_ADMIN, access: "read" },
                                       ])
      policy.save!
    end

    unless Hydra::AdminPolicy.exists?(DISCOVERY_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: DISCOVERY_POLICY_ID, title: ["Discovery access only"])
      policy.default_permissions.build([
                                         { type: "group", name: META_ADMIN, access: "edit" },
                                         { type: "group", name: RIGHTS_ADMIN, access: "read" },
                                         { type: "group", name: PUBLIC_GROUP, access: "discover" },
                                       ])
      policy.save!
    end

    # TODO: Is this policy actually needed?
    unless Hydra::AdminPolicy.exists?(UCSB_CAMPUS_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: UCSB_CAMPUS_POLICY_ID, title: ["Campus use only, requires UCSB login"])
      policy.default_permissions.build([
                                         { type: "group", name: META_ADMIN, access: "edit" },
                                         { type: "group", name: RIGHTS_ADMIN, access: "read" },
                                         { type: "group", name: UCSB_CAMPUS_GROUP, access: "read" },
                                         { type: "group", name: PUBLIC_GROUP, access: "discover" },
                                       ])
      policy.save!
    end

    unless Hydra::AdminPolicy.exists?(UCSB_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: UCSB_POLICY_ID, title: ["UCSB users only"])
      policy.default_permissions.build([
                                         { type: "group", name: META_ADMIN, access: "edit" },
                                         { type: "group", name: RIGHTS_ADMIN, access: "read" },
                                         { type: "group", name: UCSB_GROUP, access: "read" },
                                         { type: "group", name: PUBLIC_GROUP, access: "discover" },
                                       ])
      policy.save!
    end

    unless Hydra::AdminPolicy.exists?(UC_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: UC_POLICY_ID, title: ["UC users only"])
      policy.default_permissions.build([
                                         { type: "group", name: META_ADMIN, access: "edit" },
                                         { type: "group", name: RIGHTS_ADMIN, access: "read" },
                                         { type: "group", name: UCSB_GROUP, access: "read" },
                                         { type: "group", name: UC_GROUP, access: "read" },
                                         { type: "group", name: PUBLIC_GROUP, access: "discover" },
                                       ])
      policy.save!
    end

    unless Hydra::AdminPolicy.exists?(PUBLIC_CAMPUS_POLICY_ID)
      policy = Hydra::AdminPolicy.create(id: PUBLIC_CAMPUS_POLICY_ID, title: ["Public Access, Campus use only"])
      policy.default_permissions.build([
                                         { type: "group", name: META_ADMIN, access: "edit" },
                                         { type: "group", name: RIGHTS_ADMIN, access: "read" },
                                         { type: "group", name: PUBLIC_CAMPUS_GROUP, access: "read" },
                                         { type: "group", name: PUBLIC_GROUP, access: "discover" },
                                       ])
      policy.save!
    end

    return if Hydra::AdminPolicy.exists?(PUBLIC_POLICY_ID)
    policy = Hydra::AdminPolicy.create(id: PUBLIC_POLICY_ID, title: ["Public access"])
    policy.default_permissions.build([
                                       { type: "group", name: META_ADMIN, access: "edit" },
                                       { type: "group", name: RIGHTS_ADMIN, access: "read" },
                                       { type: "group", name: PUBLIC_GROUP, access: "read" },
                                     ])
    policy.save!
  end
end
