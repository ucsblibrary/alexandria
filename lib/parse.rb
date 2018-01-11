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
end
