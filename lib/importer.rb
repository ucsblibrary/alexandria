factory_dir = File.join(File.dirname(__FILE__), 'importer', 'factories')
Dir[File.join(factory_dir, '**', '*.rb')].each do |file|
  Rails.logger.debug "Requiring #{file}"
  require file
end

module Importer
  extend ActiveSupport::Autoload
  autoload :CSV
  autoload :Cylinder
  autoload :ETD
  autoload :Factory
  autoload :LocalAuthorityImporter
  autoload :Mods
end
