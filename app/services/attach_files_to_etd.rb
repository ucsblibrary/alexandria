class AttachFilesToETD
  def self.run(etd, pdf_file_name)
    AttachFilesToETD.new(etd, pdf_file_name).run
  end

  attr_reader :etd, :pdf_file_name

  def initialize(etd, pdf_file_name)
    @etd = etd
    @pdf_file_name = pdf_file_name
  end

  def run
    Dir.mktmpdir do |tmpdir|
      files = zip_service.extract_files(tmpdir)
      return unless files

      if files.proquest
        attach_proquest(files.proquest)
        UpdateMetadataFromProquestFile.new(etd).run
        etd.proquest.content.rewind
      end

      attach_original_and_supplimentals([files.pdf] + files.supplemental)
    end
  end

  private

    def zip_service
      @zip_service ||= ZipfileService.new(pdf_file_name)
    end

    def attach_original_and_supplimentals(paths)
      paths.each do |path|
        file_set = FileSet.new
        puts "  Attaching binary #{path}"
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            File.new(path),
                                            :original_file)
        etd.ordered_members << file_set
      end
    end

    def attach_proquest(path)
      etd.proquest.mime_type = 'application/xml'
      etd.proquest.original_name = File.basename(path)
      etd.proquest.content = File.new(path)
    end

    def best_mime_for_filename(file_name)
      mime_types = MIME::Types.of(file_name)
      mime_types.empty? ? 'application/octet-stream' : mime_types.first.content_type
    end
end
