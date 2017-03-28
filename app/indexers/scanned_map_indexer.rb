# frozen_string_literal: true

class ScannedMapIndexer < ObjectIndexer
  def generate_solr_document
    super do |solr_doc|
      solr_doc["image_url_ssm"] = file_set_images
      solr_doc["large_image_url_ssm"] = file_set_large_images
      solr_doc["file_set_iiif_manifest_ssm"] = file_set_iiif_manifests
      solr_doc[ISSUED] = issued
      solr_doc[COPYRIGHTED] = display_date("date_copyrighted")
      solr_doc["rights_holder_label_tesim"] = object["rights_holder"].flat_map(&:rdf_label)
    end
  end

  private

    # Called by the CurationConcerns::WorkIndexer
    def thumbnail_path
      file_set_images("300,")
    end

    def file_set_large_images
      file_set_images("1000,")
    end

    def file_set_images(size = "400,")
      object.file_sets.map do |file_set|
        file = file_set.files.first
        next unless file
        Riiif::Engine.routes.url_helpers.image_url(
          file.id,
          size: size,
          only_path: true
        )
      end
    end

    def file_set_iiif_manifests
      object.file_sets.map do |file_set|
        file = file_set.files.first
        next unless file
        Riiif::Engine.routes.url_helpers.info_path(file.id)
      end
    end

    def issued
      return unless object.issued.present?
      object.issued.first.display_label
    end
end
