class EtdsController < ApplicationController
  include Hydra::Controller::ControllerBehavior
  include ConvertIds

  before_action :convert_ark_to_id, only: :update
  load_resource class: ETD

  def update
    authorize! :update_rights, @etd
    @etd.visibility_during_embargo = resource_for(etd_params[:visibility_during_embargo])
    @etd.visibility_after_embargo = resource_for(etd_params[:visibility_after_embargo])
    @etd.embargo_release_date = etd_params[:embargo_release_date]
    @etd.save!
    redirect_to catalog_path(@etd)
  end

  protected

    def resource_for(id)
      RDF::URI(ActiveFedora::Base.id_to_uri(id))
    end

    def etd_params
      @etd_params ||= params.require(:etd).permit(:visibility_during_embargo, :visibility_after_embargo, :embargo_release_date)
    end
end
