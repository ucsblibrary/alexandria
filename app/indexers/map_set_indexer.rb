# frozen_string_literal: true

class MapSetIndexer < ObjectIndexer
  MAP_SORT_FIELD = "accession_number_si asc"

  def thumbnail_path
    ActionController::Base.helpers.image_path(
      "fontawesome/black/png/256/map.png"
    )
  end

  def generate_solr_document
    super do |solr_doc|
      query = ActiveFedora::SolrQueryBuilder.construct_query(
        parent_id_ssim: object.id
      )
      results = ActiveFedora::SolrService.query(
        query,
        fl: "id has_model_ssim",
        sort: MAP_SORT_FIELD,
        rows: ActiveFedora::Base.count
      )

      component_maps = results.reject do |doc|
        doc["has_model_ssim"].include? "IndexMap"
      end

      solr_doc["component_maps_ssim"] = component_maps.map(&:id)

      solr_doc["index_maps_ssim"] = object.index_map_id.sort

      solr_doc[COPYRIGHTED] = display_date("date_copyrighted")
      solr_doc[ISSUED] = issued
    end
  end
end
