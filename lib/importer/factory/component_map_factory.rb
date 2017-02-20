# frozen_string_literal: true
module Importer::Factory
  class ComponentMapFactory < ObjectFactory
    include WithAssociatedCollection

    self.klass = ComponentMap
    self.system_identifier_field = :accession_number

    def attach_files(object, files)
      files.each do |f|
        unless File.file?(f)
          $stderr.puts "No file exists at #{f}"
          raise IngestError
        end
        file_set = FileSet.new(admin_policy_id: object.admin_policy_id)
        Rails.logger.debug "Attaching binary #{File.basename(f)}"
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            File.new(f),
                                            :original_file)
        object.ordered_members << file_set
      end
    end
  end
end
