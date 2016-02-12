class ImageIndexer < ObjectIndexer
  def generate_solr_document
    super do |solr_doc|
      # TODO: the CurationConcern::WorkIndexer also indexes thumbnails. De-duplicate
      solr_doc['thumbnail_url_ssm'.freeze] = file_set_thumbnails
      solr_doc['image_url_ssm'.freeze] = file_set_images
      solr_doc['large_image_url_ssm'.freeze] = file_set_large_images
      solr_doc[ISSUED] = issued
      solr_doc[COPYRIGHTED] = display_date('date_copyrighted'.freeze)
      solr_doc['rights_holder_label_tesim'.freeze] = object['rights_holder'.freeze].flat_map(&:rdf_label)
    end
  end

  private

    def file_set_thumbnails
      file_set_images('300,'.freeze)
    end

    def file_set_large_images
      file_set_images('1000,'.freeze)
    end

    def file_set_images(size = '600,'.freeze)
      object.file_sets.map do |file_set|
        file = file_set.files.first
        next unless file
        Riiif::Engine.routes.url_helpers.image_url(
          file.id,
          size: size,
          host: host
        )
      end
    end

    def host
      hostname = Rails.application.config.host_name
      if hostname == 'localhost'.freeze || hostname == '127.0.0.1'.freeze
        "#{hostname}:#{Rails.application.secrets.localhost_port}"
      else
        hostname
      end
    rescue NoMethodError
      raise 'host_name is not configured'
    end

    def issued
      return unless object.issued.present?
      object.issued.first.display_label
    end
end
