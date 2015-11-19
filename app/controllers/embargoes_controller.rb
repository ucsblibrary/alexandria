class EmbargoesController < ApplicationController
  include Hydra::Collections::AcceptsBatches
  include Hydra::Controller::ControllerBehavior
  include ConvertIds

  before_action :convert_ark_to_id, only: [:destroy]

  attr_accessor :curation_concern
  helper_method :curation_concern
  load_resource class: ActiveFedora::Base, instance_name: :curation_concern

  def index
    authorize! :discover, Hydra::AccessControls::Embargo
  end

  # Remove an active or lapsed embargo
  def destroy
    authorize! :update_rights, curation_concern
    remove_embargo(curation_concern)
    flash[:notice] = curation_concern.embargo_history.last
    redirect_to catalog_path(curation_concern)
  end

  def update
    filter_docs_with_rights_access!
    batch.each do |id|
      ActiveFedora::Base.find(id).tap do |curation_concern|
        remove_embargo(curation_concern)
      end
    end
    redirect_to embargoes_path
  end

  protected

    # def _prefixes
    #   # This allows us to use the unauthorized template in curation_concern/base
    #   @_prefixes ||= super + ['curation_concern/base']
    # end

    def filter_docs_with_rights_access!
      filter_docs_with_access!(:update_rights)
    end

    def remove_embargo(work)
      work.embargo_visibility! # If the embargo has lapsed, update the current visibility.
      work.deactivate_embargo!
      work.save
    end
end
