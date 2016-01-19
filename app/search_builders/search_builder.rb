class SearchBuilder < Hydra::SearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
  include BlacklightRangeLimit::RangeLimitBuilder

  # This applies appropriate access controls to all solr queries
  self.default_processor_chain += [:add_access_controls_to_solr_params, :only_visible_objects]

  def only_visible_objects(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=has_model_ssim}#{Image.to_class_uri},ETD"
  end
end
