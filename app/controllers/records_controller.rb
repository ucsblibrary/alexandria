class RecordsController < ApplicationController
  prepend_before_action :convert_noid_to_id
  load_resource only: [:destroy]
  load_and_authorize_resource only: [:new_merge, :merge]

  include RecordsControllerBehavior

  def destroy
    # Assume for now that the only type of records we can
    # delete using the UI are local authorities.
    authorize! :destroy, :local_authorities

    references = Record.references_for(@record)
    if references.empty?
      flash[:notice] = "Record \"#{@record.rdf_label.first}\" has been destroyed"
      @record.destroy
    else
      flash[:alert] = "Record \"#{@record.rdf_label.first}\" cannot be deleted because it is referenced by #{references.count} other #{'record'.pluralize(references.count)}."
    end

    redirect_to local_authorities_path
  end

  # Displays the form to merge records
  def new_merge
    if LocalAuthority.local_authority?(@record)
      new_merge_form
    else
      flash[:alert] = 'This record cannot be merged.  Only local authority records can be merged.'
      redirect_to local_authorities_path
    end
  end

  def merge
    uri = fetch_merge_target
    if !uri.blank?
      merge_target_id = ActiveFedora::Base.uri_to_id(uri)
      MergeRecordsJob.perform_later(@record.id, merge_target_id, current_user.user_key)
      flash[:notice] = 'A background job has been queued to merge the records.'
      redirect_to local_authorities_path
    else
      flash[:alert] = 'Error:  Unable to queue merge job.  Please fill in all required fields.'
      new_merge_form
      render :new_merge
    end
  end

  private

    # Override method from hydra-editor to insert record origin
    def set_attributes
      super
      if resource.respond_to?(:record_origin) && resource.new_record?
        resource.record_origin << "#{Time.now.utc.to_s(:iso8601)} Record originated in ADRL"
      end
      resource.attributes
    end

    def new_merge_form
      form_class = @record.is_a?(Agent) ? NameMergeForm : SubjectMergeForm
      @form = form_class.new(@record)
    end

    def fetch_merge_target
      attrs = params.select { |key| key.match(/^.*merge_target_attributes$/) }.values.first || {}
      attrs.fetch('0', {}).fetch('id', nil)
    end

    def convert_noid_to_id
      return unless params[:id]
      if id = Identifier.treeify(params[:id])
        params[:id] = id
      end
    end
end
