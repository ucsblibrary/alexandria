# Generated via
#  `rails generate curation_concerns:work MapSet`

module CurationConcerns
  class MapSetsController < ApplicationController
    include CurationConcerns::CurationConcernController
    self.curation_concern_type = MapSet
    self.theme = "alexandria"

    # Gives the class of the show presenter. Override this if you want
    # to use a different presenter.
    def show_presenter
      # CurationConcerns::WorkShowPresenter
      ::MapSetPresenter
    end

    def search_builder_class
      ::WorkSearchBuilder
    end

    # Overrides the Blacklight::Catalog to point at main_app
    def search_action_url(options = {})
      main_app.search_catalog_path(options)
    end
  end
end
