class AttachFilesToImage
  def self.run(image, files_directory, file_name)
    AttachFilesToImage.new(image, files_directory, file_name).run
  end

  attr_reader :image, :files_directory, :file_names

  def initialize(image, files_directory, file_names)
    @image = image
    @files_directory = files_directory
    @file_names = file_names
  end

  def run
    # only attach files once
    return if image.file_sets.count > 0
    file_names.each do |file_path|
      create_file(file_path)
    end
  end

  private

    def create_file(file_name)
      path = image_path(file_name)
      unless File.exist?(path)
        puts "  * File doesn't exist at #{path}"
        return
      end
      file_set = FileSet.new(admin_policy_id: image.admin_policy_id)
      puts "  Attaching binary #{file_name}"
      Hydra::Works::AddFileToFileSet.call(file_set,
                                          File.new(path),
                                          :original_file)
      image.ordered_members << file_set
    end

    def image_path(file_name)
      File.join(files_directory, file_name)
    end
end
