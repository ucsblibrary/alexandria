# frozen_string_literal: true

class Ability
  # For fedora objects that have an admin policy assigned to
  # them, some of the rights that a user will be granted are
  # defined in the policy file:  app/models/admin_policy.rb
  include Hydra::PolicyAwareAbility

  attr_reader :on_campus

  def initialize(user, on_campus = false)
    @on_campus = on_campus
    super
  end

  # Define any customized permissions here.
  def custom_permissions
    # Don't allow downloading originals of Audio files.
    can :download_original, FileSet do |fs|
      # TODO: Load parent class from Solr, it'll be faster
      !fs.parent.is_a?(AudioRecording) && can?(:read, fs)
    end
    metadata_admin_permissions
    rights_admin_permissions
    discover_permissions
  end

  # This method is required to exist by curation_concerns gem,
  # but we want to rely on our AdminPolicy behavior instead, so
  # just return false.
  def admin?
    false
  end

  def metadata_admin_permissions
    return unless user_groups.include?(AdminPolicy::META_ADMIN)

    can [:create, :update], ActiveFedora::Base
    can :update, SolrDocument
    can [:read, :destroy], :local_authorities
    can [:new_merge, :merge], [ActiveFedora::Base, SolrDocument]

    # Allow admins to download originals of AudioRecordings
    can :download_original, FileSet
  end

  def rights_admin_permissions
    return unless user_groups.include?(AdminPolicy::RIGHTS_ADMIN)

    can :discover, Hydra::AccessControls::Embargo
    can :update_rights, [ActiveFedora::Base, SolrDocument, String]
  end

  # The read and edit permissions are taken care of by the
  # hydra-access-controls gem, but the discover permissions
  # are not, so we define them here.
  def discover_permissions
    can :discover, String do |id|
      test_access(access: :discover, object_id: id)
    end

    can :discover, ActiveFedora::Base.descendants - [Hydra::AccessControls::Embargo] do |obj|
      test_access(access: :discover, object_id: obj.id)
    end

    can :discover, SolrDocument do |obj|
      cache.put(obj.id, obj)
      test_access(access: :discover, object_id: obj.id)
    end
  end

  # @param [Symbol] access E.g., :discover, :read
  # @param [String] object_id
  def test_access(access:, object_id:)
    policy_id = policy_id_for(object_id)
    return false if policy_id.nil?

    Rails.logger.debug("[CANCAN] -policy- Does the POLICY #{policy_id} provide #{access} permissions for #{current_user.user_key}?")

    group_intersection = user_groups & groups_from_policy(access: access,
                                                          policy_id: policy_id)
    result = group_intersection.present?

    Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
    result
  end

  # Returns the list of groups that are granted DISCOVER access
  # by the policy object identified by policy_id.
  # Note:  Edit or read access implies discover access, so the
  # resulting list of groups is the union of edit, read, and
  # discover groups.
  #
  # @param [Symbol] access E.g., :discover, :read
  # @param [AdminPolicy] policy_id
  def groups_from_policy(access:, policy_id:)
    groups = []
    policy_permissions = policy_permissions_doc(policy_id)

    if policy_permissions.present?
      field_name = Hydra.config.permissions.inheritable[access][:group]
      groups = read_groups_from_policy(policy_id) |
               policy_permissions.fetch(field_name, [])
    end

    Rails.logger.debug("[CANCAN] -policy- #{access}_groups: #{groups.inspect}")
    groups
  end

  def user_groups
    groups = super

    if on_campus
      groups += [AdminPolicy::PUBLIC_CAMPUS_GROUP]
      groups += [AdminPolicy::UCSB_CAMPUS_GROUP] if current_user.ucsb_user?
    end

    groups
  end
end
