require_relative 'settings'

LinkedVocabs.add_vocabulary('lcsh', 'http://id.loc.gov/authorities/subjects/')
LinkedVocabs.add_vocabulary('lcnames', 'http://id.loc.gov/authorities/names/')
LinkedVocabs.add_vocabulary('iso_639_2', 'http://id.loc.gov/vocabulary/iso639-2/')
LinkedVocabs.add_vocabulary('eurights', 'http://www.europeana.eu/rights/')
LinkedVocabs.add_vocabulary('ccpublic', 'http://creativecommons.org/publicdomain/')
LinkedVocabs.add_vocabulary('tgm', 'http://id.loc.gov/vocabulary/graphicMaterials')
LinkedVocabs.add_vocabulary('aat', 'http://vocab.getty.edu/aat/')
LinkedVocabs.add_vocabulary('local', Settings.internal_local_vocab_root)
LinkedVocabs.add_vocabulary('cclicenses', 'http://creativecommons.org/licenses/')
LinkedVocabs.add_vocabulary('rights', 'http://opaquenamespace.org/ns/rights/')
LinkedVocabs.add_vocabulary('lc_orgs', 'http://id.loc.gov/vocabulary/organizations/')
LinkedVocabs.add_vocabulary('ldp', 'http://www.w3.org/ns/ldp#')
LinkedVocabs.add_vocabulary('lccs', 'http://id.loc.gov/vocabulary/preservation/copyrightStatus')

require 'vocabularies/local'
Oargun::ControlledVocabularies::Creator.use_vocabulary :lcnames, class: Oargun::Vocabularies::LCNAMES
Oargun::ControlledVocabularies::Creator.use_vocabulary :local, class: Vocabularies::LOCAL

Oargun::ControlledVocabularies::Subject.use_vocabulary :local, class: Vocabularies::LOCAL
