# frozen_string_literal: true
class MapSetPresenter < CurationConcerns::WorkShowPresenter
  delegate(
    :accession_number,
    :alternative,
    :ark,
    :citation,
    :collection,
    :copyright_status,
    :extent,
    :form_of_work,
    :fulltext_link,
    :issue_number,
    :issued,
    :license,
    :location,
    :matrix_number,
    :notes,
    :place_of_publication,
    :restrictions,
    :rights_holder,
    :sub_location,
    :table_of_contents,
    :work_type,
    :scale,
    to: :solr_document
  )

  def index_map_ids
    fetch("index_maps_ssim", [])
  end

  def component_map_ids
    fetch("component_maps_ssim", [])
  end

  # @param [Array<String>] ids a list of ids to build presenters for
  # @param [Class] presenter_class the type of presenter to build
  # @return [Array<presenter_class>] presenters for the ordered_members (not filtered by class)
  def index_map_presenters(ids = index_map_ids, presenter_class = IndexMapPresenter)
    CurationConcerns::PresenterFactory.build_presenters(ids, presenter_class, *presenter_factory_arguments)
  end

  # @param [Array<String>] ids a list of ids to build presenters for
  # @param [Class] presenter_class the type of presenter to build
  # @return [Array<presenter_class>] presenters for the ordered_members (not filtered by class)
  def component_map_presenters(ids = component_map_ids, presenter_class = ComponentMapPresenter)
    CurationConcerns::PresenterFactory.build_presenters(ids, presenter_class, *presenter_factory_arguments)
  end
end
