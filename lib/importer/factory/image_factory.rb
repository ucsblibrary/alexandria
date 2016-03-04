module Importer::Factory
  class ImageFactory < ObjectFactory
    include WithAssociatedCollection

    self.klass = Image
    self.attach_files_service = AttachFilesToImage
    self.system_identifier_field = :accession_number
  end
end
