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
    metadata_admin_permissions
    rights_admin_permissions
    discover_permissions
  end

  def metadata_admin_permissions
    return unless user_groups.include?(AdminPolicy::META_ADMIN_GROUP)

    can [:create, :update], ActiveFedora::Base
    can :update, SolrDocument
    can [:read, :destroy], :local_authorities
    can [:new_merge, :merge], [ActiveFedora::Base, SolrDocument]
  end

  def rights_admin_permissions
    return unless user_groups.include?(AdminPolicy::RIGHTS_ADMIN_GROUP)

    can :discover, Hydra::AccessControls::Embargo
    can :update_rights, [ActiveFedora::Base, SolrDocument, String]
  end

  # The read and edit permissions are taken care of by the
  # hydra-access-controls gem, but the discover permissions
  # are not, so we define them here.
  def discover_permissions
    can :discover, String do |id|
      test_discover_from_policy(id)
    end

    can :discover, ActiveFedora::Base.descendants - [Hydra::AccessControls::Embargo] do |obj|
      test_discover_from_policy(obj.id)
    end

    can :discover, SolrDocument do |obj|
      cache.put(obj.id, obj)
      test_discover_from_policy(obj.id)
    end
  end

  # Tests whether the object's admin policy grants DISCOVER access for the current user
  def test_discover_from_policy(object_id)
    policy_id = policy_id_for(object_id)
    return false if policy_id.nil?

    Rails.logger.debug("[CANCAN] -policy- Does the POLICY #{policy_id} provide DISCOVER permissions for #{current_user.user_key}?")

    group_intersection = user_groups & discover_groups_from_policy(policy_id)
    result = !group_intersection.blank?

    Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
    result
  end

  # Returns the list of groups that are granted DISCOVER access
  # by the policy object identified by policy_id.
  # Note:  Edit or read access implies discover access, so the
  # resulting list of groups is the union of edit, read, and
  # discover groups.
  def discover_groups_from_policy(policy_id)
    groups = []
    policy_permissions = policy_permissions_doc(policy_id)

    unless policy_permissions.blank?
      field_name = Hydra.config.permissions.inheritable[:discover][:group]
      groups = read_groups_from_policy(policy_id) |
               policy_permissions.fetch(field_name, [])
    end

    Rails.logger.debug("[CANCAN] -policy- discover_groups: #{groups.inspect}")
    groups
  end

  # To check if user can download a file, find the parent object
  # that the file belongs to (e.g. ETD or Image), and check
  # if the user has read permissions for that object.
  # This method comes from hydra-access-controls gem.
  def download_permissions
    can :download, FileSet do |file|
      file.in_works.any? do |parent_object|
        can? :read, parent_object
      end
    end
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
