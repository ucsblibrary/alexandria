# frozen_string_literal: true
# TODO: Merge this with CurationConcerns
# Provides a mechanism to interact with embargos.
class EmbargoesController < ApplicationController
  include CurationConcerns::Collections::AcceptsBatches
  include Hydra::Controller::ControllerBehavior

  attr_accessor :curation_concern
  helper_method :curation_concern
  load_resource class: ActiveFedora::Base, instance_name: :curation_concern

  def index
    authorize! :discover, Hydra::AccessControls::Embargo
  end

  # Deactivate an active or lapsed embargo
  def destroy
    authorize! :update_rights, curation_concern
    EmbargoService.deactivate_embargo(curation_concern)
    flash[:notice] = curation_concern.embargo_history.last
    redirect_to solr_document_path(curation_concern)
  end

  # Deactivate a batch of embargos
  def update
    filter_docs_with_rights_access!
    copy_visibility = params.fetch(:embargoes, {}).values.map { |h| h[:copy_visibility] }
    ActiveFedora::Base.find(batch).each do |curation_concern|
      CurationConcerns::Actors::EmbargoActor.new(curation_concern).destroy
      curation_concern.copy_admin_policy_to_files! if copy_visibility.include?(curation_concern.id)
    end
    redirect_to embargoes_path
  end

  protected

    def filter_docs_with_rights_access!
      filter_docs_with_access!(:update_rights)
    end
end
