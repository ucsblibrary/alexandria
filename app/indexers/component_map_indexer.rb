# frozen_string_literal: true

class ComponentMapIndexer < ObjectIndexer
  def generate_solr_document
    super do |solr_doc|
      solr_doc["file_set_iiif_manifest_ssm"] = file_set_iiif_manifests
      solr_doc["image_url_ssm"] = file_set_images
      solr_doc["index_maps_ssim"] = object.index_map_id.sort
      solr_doc["large_image_url_ssm"] = file_set_large_images

      solr_doc["rights_holder_label_tesim"] =
        object["rights_holder"].flat_map(&:rdf_label)

      solr_doc[COPYRIGHTED] = display_date("date_copyrighted")
      solr_doc[ISSUED] = issued
    end
  end
end
