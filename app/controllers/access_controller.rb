# frozen_string_literal: true

class AccessController < ApplicationController
  layout "alexandria"

  before_action :load_record
  attr_accessor :record
  helper_method :record

  def edit
    authorize! :update_rights, record

    @visibility_options = AdminPolicy.all.invert
    @current_vis = if record.embargo&.visibility_during_embargo.present?
                     ActiveFedora::Base.uri_to_id(
                       record.visibility_during_embargo.id
                     )
                   else
                     record.admin_policy_id
                   end

    @future_vis = if record.embargo&.visibility_after_embargo.present?
                    ActiveFedora::Base.uri_to_id(
                      record.visibility_after_embargo.id
                    )
                  else
                    record.admin_policy_id
                  end
  end

  def update
    handle(record, :create_or_update)
  end

  def destroy
    handle(record, :remove)
  end

  def deactivate
    handle(record, :deactivate)
  end

  protected

    # @param [ActiveFedora::Base] record
    # @param [Symbol] action Can be :remove, :deactivate, :create_or_update
    def handle(record, action)
      authorize! :update_rights, record

      if action == :create_or_update
        EmbargoService.send(
          "#{action}_embargo",
          record,
          params.permit(:admin_policy_id,
                        :visibility_after_embargo_id,
                        :embargo_release_date)
        )
      else
        EmbargoService.send("#{action}_embargo", record)
      end

      record.save!
      redirect_to main_app.solr_document_path(record)
    end

    def load_record
      @record = ActiveFedora::Base.find(params[:id])
    end
end
