# frozen_string_literal: true

# A parent MapSet might contain several ComponentMap and
# IndexMap records.  The full list of component and index maps
# is indexed on the solr document for the parent MapSet record.
# So the presenter for a ComponentMap or IndexMap can find the
# list of its sibling maps through the parent MapSet.

module WithComponents
  # For a ComponentMap or IndexMap record, this will be the ID
  # of the parent MapSet.
  def parent_id
    fetch("parent_id_ssim", nil)
  end

  # The presenter for the parent MapSet.  For a MapSet record,
  # self is already the presenter for that MapSet.
  def map_set_presenter
    return @map_set_presenter if @map_set_presenter
    @map_set_presenter = if is_a?(MapSetPresenter)
                           self
                         else
                           CurationConcerns::PresenterFactory.build_presenters(parent_id, MapSetPresenter, *presenter_factory_arguments).first
                         end
  end

  def map_set_label
    (map_set_presenter.title || []).first
  end

  def component_map_ids
    map_set_presenter.fetch("component_maps_ssim", [])
  end

  def index_map_ids
    map_set_presenter.fetch("index_maps_ssim", [])
  end

  # @param [Array<String>] ids a list of ids to build presenters for
  # @param [Class] presenter_class the type of presenter to build
  # @return [Array<presenter_class>] presenters for the ordered_members (not filtered by class)
  def component_map_presenters(ids = component_map_ids, presenter_class = ComponentMapPresenter)
    CurationConcerns::PresenterFactory.build_presenters(ids, presenter_class, *presenter_factory_arguments)
  end

  # @param [Array<String>] ids a list of ids to build presenters for
  # @param [Class] presenter_class the type of presenter to build
  # @return [Array<presenter_class>] presenters for the ordered_members (not filtered by class)
  def index_map_presenters(ids = index_map_ids, presenter_class = IndexMapPresenter)
    CurationConcerns::PresenterFactory.build_presenters(ids, presenter_class, *presenter_factory_arguments)
  end
end
