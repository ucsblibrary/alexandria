class Ability
  include Hydra::PolicyAwareAbility

  # Define any customized permissions here.
  def custom_permissions
    can :read, ActiveFedora::Base

    if current_user.groups.include?('metadata_admin')
      can [:create, :update], [ActiveFedora::Base, SolrDocument]
      can [:read, :destroy], :local_authorities

      can [:new_merge, :merge], ActiveFedora::Base
      can :download, ActiveFedora::File # an etd download
    end
  end
end
