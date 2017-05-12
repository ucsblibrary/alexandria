# frozen_string_literal: true

class CurationConcerns::FileSetsController < ApplicationController
  include CurationConcerns::FileSetsControllerBehavior

  layout "curation_concerns"

  def search_builder_class
    ::FileSetSearchBuilder
  end

  # Overrides the Blacklight::Catalog to point at main_app
  def search_action_url(options = {})
    main_app.search_catalog_path(options)
  end
end
