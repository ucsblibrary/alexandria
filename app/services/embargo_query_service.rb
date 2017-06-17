# frozen_string_literal: true

# Methods for Querying Repository to find Embargoed Objects

module EmbargoQueryService
  # Returns all assets with embargo release date set to a date in the past
  #
  # @return [Array<ActiveFedora::Base>]
  def self.assets_with_expired_embargoes
    ActiveFedora::Base.where("embargo_release_date_dtsi:[* TO NOW]")
  end

  # Scope the query to return only works.
  #
  # @return [Array<ActiveFedora::Base>]
  def self.works_with_expired_embargoes
    assets_with_expired_embargoes.where(only_works)
  end

  # Returns all assets with embargo release date set (assumes that
  # when embargo visibility is applied to assets whose embargoes have
  # expired, the embargo expiration date will be removed from its
  # metadata)
  #
  # @return [Array<ActiveFedora::Base>]
  def self.assets_under_embargo
    ActiveFedora::Base.where("embargo_release_date_dtsi:*")
  end

  # Scope the query to return only works.
  #
  # @return [Array<ActiveFedora::Base>]
  def self.works_under_embargo
    assets_under_embargo.where(only_works)
  end

  # Returns all assets that have had embargoes deactivated in the past.
  #
  # @return [Array<ActiveFedora::Base>]
  def self.assets_with_deactivated_embargoes
    ActiveFedora::Base.where("embargo_history_ssim:*")
  end

  # Scope a query to include only "works" (not FileSet or
  # Collection or any other models).
  #
  # It should return a query string like this:
  #
  # has_model_ssim:AudioRecording OR
  #   has_model_ssim:Image OR
  #   has_model_ssim:ETD
  #
  # @return [String]
  def self.only_works
    work_types = CurationConcerns.config.registered_curation_concern_types

    work_types.map do |class_name|
      "has_model_ssim:#{class_name}"
    end.join(" OR ")
  end
end
