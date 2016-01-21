class ImageIndexer < ObjectIndexer
  def generate_solr_document
    super do |solr_doc|
      solr_doc['thumbnail_url_ssm'.freeze] = file_set_thumbnails
      solr_doc['image_url_ssm'.freeze] = file_set_images
      solr_doc['large_image_url_ssm'.freeze] = file_set_large_images
      solr_doc[ISSUED] = issued
      solr_doc[COPYRIGHTED] = display_date('date_copyrighted')
      solr_doc['rights_holder_label_tesim'] = object['rights_holder'].flat_map(&:rdf_label)
    end
  end

  private

    def file_set_thumbnails
      file_set_images('300,'.freeze)
    end

    def file_set_large_images
      file_set_images('1000,'.freeze)
    end

    def file_set_images(size = '600,')
      object.member_ids.map do |id|
        Riiif::Engine.routes.url_helpers.image_url(
          "#{id}/original",
          size: size,
          host: host,
        )
      end
    end

    def host
      hostname = Rails.application.config.host_name
      if hostname == 'localhost' || hostname == '127.0.0.1'
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
