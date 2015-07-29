class Ability
  include Hydra::PolicyAwareAbility

  # Define any customized permissions here.
  def custom_permissions
    can :read, ActiveFedora::Base

    if current_user.groups.include?('metadata_admin')
      can [:create, :update], [ActiveFedora::Base, SolrDocument]
      can [:read, :destroy], :local_authorities

      can [:new_merge, :merge], [ActiveFedora::Base, SolrDocument]

      # TODO this is temporary. It should check to see if the holding object grants :read
      can :download, ActiveFedora::File # an etd download
    end

    if current_user.groups.include?('rights_admin')
      can :discover, Hydra::AccessControls::Embargo
      can :update_rights, [ActiveFedora::Base, SolrDocument, String]
    end
  end
end
