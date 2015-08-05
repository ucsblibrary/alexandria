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

  # To check if user can download a file, find the parent object
  # that the file belongs to (e.g. ETD or Image), and check
  # if the user has read permissions for that object.
  # This method comes from hydra-access-controls gem.
  def download_permissions
    can :download, ActiveFedora::File do |file|
      gf_uri = file.uri.to_s.sub(/\/[^\/]*$/, '')
      gf_id = ActiveFedora::Base.uri_to_id(gf_uri)
      gf = GenericFile.find(gf_id)
      gf.aggregated_by.any? do |parent_object|
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
