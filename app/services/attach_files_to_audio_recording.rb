class AttachFilesToAudioRecording
  def self.run(audio, files_directory, cylinder_names)
    new(audio, files_directory, cylinder_names).run
  end

  attr_reader :audio, :files_directory, :cylinder_names

  def initialize(audio, files_directory, cylinder_names)
    @audio = audio
    @files_directory = files_directory
    @cylinder_names = cylinder_names
  end

  def run
    cylinder_names.each do |cylinder_name|
      number = cylinder_name.sub(/^Cylinder /, '')
      attach_files(number)
    end
  end

  private

    def original_path(number)
      Dir.glob(File.join(files_directory, '**', "cusb-cyl#{number}a.wav")).first
    end

    def restored_path(number)
      Dir.glob(File.join(files_directory, '**', "cusb-cyl#{number}b.wav")).first
    end

    def attach_files(number)
      file_set = FileSet.create
      actor = CurationConcerns::FileSetActor.new(file_set, nil)
      attach_original(actor, number)
      attach_restored(actor, number)
      audio.ordered_members << file_set
    end

    def attach_original(actor, number)
      if orig_path = original_path(number)
        puts "  Attaching original #{orig_path}"
        actor.create_content(File.new(orig_path))
      else
        $stderr.puts "Unable to find original for #{number} in #{files_directory}"
      end
    end

    def attach_restored(actor, number)
      if rest_path = restored_path(number)
        puts "  Attaching restored #{rest_path}"
        actor.create_content(File.new(rest_path), 'restored')
      else
        $stderr.puts "Unable to find restored for #{number} in #{files_directory}"
      end
    end
end

