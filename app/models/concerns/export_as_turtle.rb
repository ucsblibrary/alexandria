module ExportAsTurtle
  def self.extended(document)
    # Register our exportable formats
    register_export_formats(document)
  end

  def self.register_export_formats(document)
    document.will_export_as(:ttl)
  end

  def export_as_ttl
    repository_model.resource.dump(:ttl)
  end

  def repository_model
    @repo_model ||= ActiveFedora::Base.find(id)
  end
end
