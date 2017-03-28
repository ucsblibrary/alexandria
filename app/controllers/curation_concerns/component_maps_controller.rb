# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work ComponentMap`

module CurationConcerns
  class ComponentMapsController < ApplicationController
    include CurationConcerns::CurationConcernController
    self.curation_concern_type = ComponentMap

    def show_presenter
      ::ComponentMapPresenter
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
