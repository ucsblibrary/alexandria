# frozen_string_literal: true

require "controlled_vocabularies"
require "vocabularies"

require_relative "settings"

VOCAB_MAP = {
  "aat" => "http://vocab.getty.edu/aat/",
  "cclicenses" => "http://creativecommons.org/licenses/",
  "ccpublic" => "http://creativecommons.org/publicdomain/",
  "eurights" => "http://www.europeana.eu/rights/",
  "iso_639_2" => "http://id.loc.gov/vocabulary/iso639-2/",
  "lc_orgs" => "http://id.loc.gov/vocabulary/organizations/",
  "lccs" => "http://id.loc.gov/vocabulary/preservation/copyrightStatus",
  "lcnames" => "http://id.loc.gov/authorities/names/",
  "lcrt" => "http://id.loc.gov/vocabulary/resourceTypes",
  "lcsh" => "http://id.loc.gov/authorities/subjects/",
  "ldp" => "http://www.w3.org/ns/ldp#",
  "local" => Settings.internal_local_vocab_root,
  "rights" => "http://opaquenamespace.org/ns/rights/",
  "rs" => "http://rightsstatements.org/vocab/",
  "tgm" => "http://id.loc.gov/vocabulary/graphicMaterials",
}.freeze

VOCAB_MAP.each do |label, uri|
  LinkedVocabs.add_vocabulary(label, uri)
end

ControlledVocabularies::RightsStatement.use_vocabulary(
  :rs, class: Vocabularies::RS
)
ControlledVocabularies::Creator.use_vocabulary(
  :lcnames, class: Vocabularies::LCNAMES
)

ControlledVocabularies::Creator.use_vocabulary(
  :local, class: Vocabularies::LOCAL
)
ControlledVocabularies::Subject.use_vocabulary(
  :local, class: Vocabularies::LOCAL
)

# During some specs we turn off the DeepIndexingService so URI labels
# don't get converted to strings; as a result the validation fails
# since Fedora URLs aren't valid in the controlled vocabulary (on
# production, the URI for a local authority is
# alexandria.ucsb.edu/organization/etc/etc rather than
# localhost:8080/fedora/rest/blah). So this is just to keep the tests
# happy.
if Rails.env.test?
  LinkedVocabs.add_vocabulary("fedora", "#{ActiveFedora.fedora.host}/")

  ControlledVocabularies::Creator.use_vocabulary(
    :fedora, class: Vocabularies::FEDORA
  )
  ControlledVocabularies::Subject.use_vocabulary(
    :fedora, class: Vocabularies::FEDORA
  )
end
