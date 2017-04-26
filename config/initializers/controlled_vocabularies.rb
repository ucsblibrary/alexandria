# frozen_string_literal: true

require "controlled_vocabularies"
require "vocabularies"

require_relative "settings"

LinkedVocabs.add_vocabulary("aat", "http://vocab.getty.edu/aat/")
LinkedVocabs.add_vocabulary("cclicenses", "http://creativecommons.org/licenses/")
LinkedVocabs.add_vocabulary("ccpublic", "http://creativecommons.org/publicdomain/")
LinkedVocabs.add_vocabulary("eurights", "http://www.europeana.eu/rights/")
LinkedVocabs.add_vocabulary("iso_639_2", "http://id.loc.gov/vocabulary/iso639-2/")
LinkedVocabs.add_vocabulary("lc_orgs", "http://id.loc.gov/vocabulary/organizations/")
LinkedVocabs.add_vocabulary("lccs", "http://id.loc.gov/vocabulary/preservation/copyrightStatus")
LinkedVocabs.add_vocabulary("lcnames", "http://id.loc.gov/authorities/names/")
LinkedVocabs.add_vocabulary("lcrt", "http://id.loc.gov/vocabulary/resourceTypes")
LinkedVocabs.add_vocabulary("lcsh", "http://id.loc.gov/authorities/subjects/")
LinkedVocabs.add_vocabulary("ldp", "http://www.w3.org/ns/ldp#")
LinkedVocabs.add_vocabulary("local", Settings.internal_local_vocab_root)
LinkedVocabs.add_vocabulary("rights", "http://opaquenamespace.org/ns/rights/")
LinkedVocabs.add_vocabulary("rs", "http://rightsstatements.org/vocab/")
LinkedVocabs.add_vocabulary("tgm", "http://id.loc.gov/vocabulary/graphicMaterials")

ControlledVocabularies::RightsStatement.use_vocabulary(
  :rs, class: Vocabularies::RS
)
ControlledVocabularies::Creator.use_vocabulary(
  :lcnames, class: Vocabularies::LCNAMES
)

ControlledVocabularies::Creator.use_vocabulary :local, class: Vocabularies::LOCAL
ControlledVocabularies::Subject.use_vocabulary :local, class: Vocabularies::LOCAL

# During some specs we turn off the DeepIndexingService so URI labels
# don't get converted to strings; as a result the validation fails
# since Fedora URLs aren't valid in the controlled vocabulary (on
# production, the URI for a local authority is
# alexandria.ucsb.edu/organization/etc/etc rather than
# localhost:8080/fedora/rest/blah). So this is just to keep the tests
# happy.
if Rails.env.test?
  LinkedVocabs.add_vocabulary("fedora", "#{ActiveFedora.fedora.host}/")

  ControlledVocabularies::Creator.use_vocabulary :fedora, class: Vocabularies::FEDORA
  ControlledVocabularies::Subject.use_vocabulary :fedora, class: Vocabularies::FEDORA
end
