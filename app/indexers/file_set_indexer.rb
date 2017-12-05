# frozen_string_literal: true

class FileSetIndexer < Hyrax::FileSetIndexer
  self.thumbnail_field = ObjectIndexer.thumbnail_field

  def generate_solr_document
    super do |solr_doc|
      if object.original_file
        # TODO: a lot of these properties are indexed in
        # Hyrax under other names
        solr_doc["original_filename_ss"] = original_filename
        solr_doc["original_file_size_ss"] = original_file_size
        Hydra::Works::CharacterizationService.run(object.original_file)
        solr_doc["height_is"] = object.original_file.height
        solr_doc["width_is"] = object.original_file.width
      end
    end
  end

  private

    def original_filename
      object.original_file.original_name
    end

    def original_file_size
      object.original_file.size
    end
end
