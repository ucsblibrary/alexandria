# frozen_string_literal: true

class MapSetIndexer < ObjectIndexer
  MAP_SORT_FIELD = "accession_number_si asc"

  def generate_solr_document
    super do |solr_doc|
      query = ActiveFedora::SolrQueryBuilder.construct_query(parent_id_ssim: object.id)
      results = ActiveFedora::SolrService.query(query, fl: "id has_model_ssim", sort: MAP_SORT_FIELD, rows: ActiveFedora::Base.count)
      index_maps, component_maps = results.partition { |doc| doc["has_model_ssim"].include? "IndexMap" }
      solr_doc["index_maps_ssim"] = index_maps.map(&:id)
      solr_doc["component_maps_ssim"] = component_maps.map(&:id)
      solr_doc[ISSUED] = issued
      solr_doc[COPYRIGHTED] = display_date("date_copyrighted")
      solr_doc["rights_holder_label_tesim"] = object["rights_holder"].flat_map(&:rdf_label)
    end
  end
end
