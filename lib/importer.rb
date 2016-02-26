factory_dir = File.join(File.dirname(__FILE__), 'importer', 'factories')
Dir[File.join(factory_dir, '**', '*.rb')].each do |file|
  puts "Requiring #{file}"
  require file
end

module Importer
  extend ActiveSupport::Autoload
  autoload :ModsImporter
  autoload :CSVImporter
  autoload :ETDImporter
  autoload :LocalAuthorityImporter
  autoload :ModsParser
  autoload :CSVParser
  autoload :Factory
end
