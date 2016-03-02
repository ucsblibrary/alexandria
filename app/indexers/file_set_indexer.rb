class FileSetIndexer < CurationConcerns::FileSetIndexer
  self.thumbnail_field = ObjectIndexer.thumbnail_field
  def generate_solr_document
    super do |solr_doc|
      if object.original_file
        # TODO: a lot of these properties are indexed in CurationConcerns under other names
        solr_doc['original_download_url_ss'.freeze] = original_download_url
        solr_doc['original_filename_ss'.freeze] = original_filename
        solr_doc['original_file_size_ss'.freeze] = original_file_size
      end
    end
  end

  private

    def original_download_url
      Rails.application.routes.url_helpers.download_url(object.id, host: host)
    end

    def original_filename
      object.original_file.original_name
    end

    def original_file_size
      object.original_file.size
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
end
