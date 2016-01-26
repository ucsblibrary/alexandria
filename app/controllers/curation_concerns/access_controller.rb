class CurationConcerns::AccessController < ApplicationController
  include Hydra::Controller::ControllerBehavior

  before_action :load_curation_concern
  attr_accessor :curation_concern
  helper_method :curation_concern

  def edit
    authorize! :update_rights, curation_concern
    @form = EmbargoForm.new(curation_concern)
  end

  def update
    authorize! :update_rights, curation_concern
    if etd_params.delete(:embargo) == 'true'
      EmbargoService.create_or_update_embargo(curation_concern, etd_params)
    else
      curation_concern.admin_policy_id = etd_params.fetch(:admin_policy_id)
      EmbargoService.remove_embargo(curation_concern)
    end
    curation_concern.save!
    redirect_to main_app.solr_document_path(curation_concern)
  end

  def destroy
    authorize! :update_rights, curation_concern
    EmbargoService.remove_embargo(curation_concern)
    curation_concern.save!
    redirect_to main_app.solr_document_path(curation_concern)
  end

  protected

    def load_curation_concern
      id = params[:etd_id] || params[:image_id]
      @curation_concern = ActiveFedora::Base.find(id)
    end

    def etd_params
      # TODO: update
      @etd_params ||= params.require(:etd).permit(:embargo, :admin_policy_id, :visibility_after_embargo_id, :embargo_release_date)
    end

    def deny_access(exception)
      if params[:action] == 'edit'
        redirect_to main_app.solr_document_path(curation_concern), alert: exception.message
      else
        super
      end
    end
end
