# frozen_string_literal: true

module AdminPolicy
  # A fedora object can have one of these policies
  RESTRICTED_POLICY_ID    = "authorities/policies/restricted"
  DISCOVERY_POLICY_ID     = "authorities/policies/discovery"
  UCSB_CAMPUS_POLICY_ID   = "authorities/policies/ucsb_on_campus"
  UCSB_POLICY_ID          = "authorities/policies/ucsb"
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

  POLICY_DEFINITIONS = {
    restricted: {
      id: RESTRICTED_POLICY_ID,
      title: ["Restricted access"],
      permissions:
        [
          { type: "group", name: META_ADMIN, access: "edit" },
          { type: "group", name: RIGHTS_ADMIN, access: "read" },
        ],
    },
    discovery: {
      id: DISCOVERY_POLICY_ID,
      title: ["Discovery access only"],
      permissions:
        [
          { type: "group", name: META_ADMIN, access: "edit" },
          { type: "group", name: RIGHTS_ADMIN, access: "read" },
          { type: "group", name: PUBLIC_GROUP, access: "discover" },
        ],
    },
    ucsb_campus: {
      id: UCSB_CAMPUS_POLICY_ID,
      title: ["Campus use only, requires UCSB login"],
      permissions:
        [
          { type: "group", name: META_ADMIN, access: "edit" },
          { type: "group", name: RIGHTS_ADMIN, access: "read" },
          { type: "group", name: UCSB_CAMPUS_GROUP, access: "read" },
          { type: "group", name: PUBLIC_GROUP, access: "discover" },
        ],
    },
    ucsb: {
      id: UCSB_POLICY_ID,
      title: ["UCSB users only"],
      permissions:
        [
          { type: "group", name: META_ADMIN, access: "edit" },
          { type: "group", name: RIGHTS_ADMIN, access: "read" },
          { type: "group", name: UCSB_GROUP, access: "read" },
          { type: "group", name: PUBLIC_GROUP, access: "discover" },
        ],
    },
    public_campus: {
      id: PUBLIC_CAMPUS_POLICY_ID,
      title: ["Public Access, Campus use only"],
      permissions:
        [
          { type: "group", name: META_ADMIN, access: "edit" },
          { type: "group", name: RIGHTS_ADMIN, access: "read" },
          { type: "group", name: PUBLIC_CAMPUS_GROUP, access: "read" },
          { type: "group", name: PUBLIC_GROUP, access: "discover" },
        ],
    },
    public: {
      id: PUBLIC_POLICY_ID,
      title: ["Public access"],
      permissions:
        [
          { type: "group", name: META_ADMIN, access: "edit" },
          { type: "group", name: RIGHTS_ADMIN, access: "read" },
          { type: "group", name: PUBLIC_GROUP, access: "read" },
        ],
    },
  }.freeze

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
    POLICY_DEFINITIONS.values.each do |defn|
      next if Hydra::AdminPolicy.exists?(defn[:id])

      policy = Hydra::AdminPolicy.create(
        id: defn[:id], title: defn[:title]
      )
      policy.default_permissions.build(defn[:permissions])
      policy.save!
    end
  end
end
