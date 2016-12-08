$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'pry-byebug' unless ENV['CI']
require 'oargun'
LinkedVocabs.add_vocabulary('lcsh', 'http://id.loc.gov/authorities/subjects/')
LinkedVocabs.add_vocabulary('lcnames', 'http://id.loc.gov/authorities/names/')
LinkedVocabs.add_vocabulary('iso_639_2', 'http://id.loc.gov/vocabulary/iso639-2/')
LinkedVocabs.add_vocabulary('eurights', 'http://www.europeana.eu/rights/')
LinkedVocabs.add_vocabulary('ccpublic', 'http://creativecommons.org/publicdomain/')
LinkedVocabs.add_vocabulary('tgm', 'http://id.loc.gov/vocabulary/graphicMaterials')
LinkedVocabs.add_vocabulary('aat', 'http://vocab.getty.edu/aat/')
LinkedVocabs.add_vocabulary('cclicenses', 'http://creativecommons.org/licenses/')
LinkedVocabs.add_vocabulary('rights', 'http://opaquenamespace.org/ns/rights/')
LinkedVocabs.add_vocabulary('lc_orgs', 'http://id.loc.gov/vocabulary/organizations/')
LinkedVocabs.add_vocabulary('ldp', 'http://www.w3.org/ns/ldp#')

module Rails
  def self.env
    'test'
  end
  class Engine
    def self.isolate_namespace(*)
      #nop
    end
  end
end

ActiveTriples::Repositories.add_repository :vocabs, RDF::Repository.new


require 'webmock/rspec'
# Allow http connections on localhost
WebMock.disable_net_connect!(allow_localhost: true)


RSpec.configure do |config|

end
