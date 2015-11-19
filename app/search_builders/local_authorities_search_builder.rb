class LocalAuthoritiesSearchBuilder < Hydra::SearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement

  def only_models_for_local_authorities(solr_params)
    solr_params[:fq] ||= []
    solr_params[:fq] << "{!terms f=has_model_ssim}#{LocalAuthority.local_authority_models.join(',')}"
  end
end
