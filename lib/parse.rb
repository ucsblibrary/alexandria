# frozen_string_literal: true

module Parse
  extend ActiveSupport::Autoload

  autoload :CSV
  autoload :ETD
  autoload :MODS

  def self.find_paths(params, extension = nil)
    return [] if params.blank?

    params.map do |arg|
      next arg if File.file?(arg)

      next unless Dir.exist?(arg)

      Find.find(arg).map do |path|
        next if File.directory?(path)
        next if extension.present? && File.extname(path) != extension

        path
      end
    end.flatten.compact
  end

  # We have two indicators of where the associated binary data will be: the
  # 'files' attribute from the metadata itself, and the set of paths passed
  # using the `-d` flag with the CLI.
  #
  # If the path(s) specified in the metadata, when appended to
  # {Settings.binary_source_root}, yields an existent file, we use that.
  # Otherwise we'll search through the paths given with `-d` in order to find a
  # match.
  #
  # @param path [Array<String>]
  # @param data_args [Array<String>]
  # @return [String]
  def self.get_binary_paths(paths, data_args)
    return [] if paths.blank?

    paths.map do |path|
      # when Pathname#join is called with a path that begins with a backslash,
      # it's assumed to be an absolute path and the prefix part of the path is
      # ignored
      normalized_path = path.sub(%r{^\/}, "")
      explicit_path = Pathname.new(Settings.binary_source_root).join(normalized_path)

      if explicit_path.exist?
        explicit_path.to_s
      else
        ::Parse.find_paths(data_args).select { |d| path.include? File.basename(d) }
      end
    end.flatten
  end
end
