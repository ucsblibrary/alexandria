class ImageIndexer < ObjectIndexer
  def generate_solr_document
    super do |solr_doc|
      solr_doc['thumbnail_url_ssm'.freeze] = generic_file_thumbnails
      solr_doc['image_url_ssm'.freeze] = generic_file_images
      solr_doc['large_image_url_ssm'.freeze] = generic_file_large_images
      solr_doc[ISSUED] = issued
      solr_doc[COPYRIGHTED] = display_date('date_copyrighted')
      solr_doc['rights_holder_label_tesim'] = object['rights_holder'].flat_map(&:rdf_label)
    end
  end

  private

    def generic_file_thumbnails
      generic_file_images('300,'.freeze)
    end

    def generic_file_large_images
      generic_file_images('1000,'.freeze)
    end

    def generic_file_images(size = '600,')
      object.generic_file_ids.map do |id|
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
        # TODO: does this have to be hard-coded?  Is the Vagrant port
        # only specified in Vagrantfile and the Apache conf?
        hostname + ':8484'
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
