# frozen_string_literal: true
# Generated via
#  `rails generate curation_concerns:work IndexMap`

module CurationConcerns
  class IndexMapsController < ApplicationController
    include CurationConcerns::CurationConcernController
    self.curation_concern_type = IndexMap

    def show_presenter
      ::IndexMapPresenter
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
