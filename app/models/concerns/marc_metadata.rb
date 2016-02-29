# Fields common to both ETDs and AudioRecordings
module MarcMetadata
  extend ActiveSupport::Concern

  included do
    property :marc_subjects, predicate: ::RDF::Vocab::DC11.subject do |index|
      index.as :stored_searchable, :facetable
    end

    property :fulltext_link, predicate: ::RDF::Vocab::Bibframe.otherEdition do |index|
      index.as :displayable
    end

    property :system_number, predicate: ::RDF::Vocab::MODS.recordIdentifier do |index|
      index.as :symbol
    end

    property :date_copyrighted, predicate: ::RDF::Vocab::DC.dateCopyrighted
  end
end
