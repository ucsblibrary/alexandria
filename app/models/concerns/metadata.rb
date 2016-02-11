require 'concerns/relators'
module Metadata
  extend ActiveSupport::Concern

  RELATIONS = {
    contributor:         RDF::Vocab::DC.contributor,
    creator:             RDF::Vocab::DC.creator,
  }.merge(MARCREL)

  included do
    # For ARKs
    property :identifier, predicate: RDF::Vocab::DC.identifier do |index|
      index.as :displayable
    end

    property :accession_number, predicate: RDF::URI('http://opaquenamespace.org/ns/cco/accessionNumber') do |index|
      index.as :symbol, :stored_searchable # symbol is needed for exact match search in the CollectionFactory
    end

    property :alternative, predicate: RDF::Vocab::DC.alternative do |index|
      index.as :stored_searchable
    end

    RELATIONS.each do |field_name, predicate|
      property field_name, predicate: predicate, class_name: Oargun::ControlledVocabularies::Creator do |index|
        index.as :stored_searchable, :facetable
      end
    end

    # property :creator, predicate: ::RDF::Vocab::DC.creator, class_name: Oargun::ControlledVocabularies::Creator do |index|
    #   index.as :stored_searchable, :facetable
    # end
    # property :contributor, predicate: ::RDF::Vocab::DC.contributor do |index|
    #   index.as :stored_searchable
    # end

    property :description, predicate: RDF::Vocab::DC.description do |index|
      index.as :stored_searchable
    end

    property :latitude, predicate: RDF::Vocab::EXIF.gpsLatitude do |index|
      index.as :displayable
    end

    property :language, predicate: RDF::Vocab::DC.language,
                        class_name: Oargun::ControlledVocabularies::Language do |index|
      index.as :displayable
    end

    property :longitude, predicate: RDF::Vocab::EXIF.gpsLongitude do |index|
      index.as :displayable
    end

    property :location, predicate: RDF::Vocab::DC.spatial,
                        class_name: Oargun::ControlledVocabularies::Geographic do |index|
      index.as :stored_searchable, :facetable
    end

    property :place_of_publication, predicate: RDF::Vocab::MARCRelators.pup do |index|
      index.as :stored_searchable
    end

    property :lc_subject, predicate: RDF::Vocab::DC.subject, class_name: Oargun::ControlledVocabularies::Subject do |index|
      index.as :stored_searchable, :facetable
    end

    validates_vocabulary_of :lc_subject

    property :institution, predicate: Oargun::Vocabularies::OARGUN.contributingInstitution, class_name: Oargun::ControlledVocabularies::Organization do |index|
      index.as :stored_searchable
    end

    validates_vocabulary_of :institution

    property :publisher, predicate: RDF::Vocab::DC.publisher do |index|
      index.as :stored_searchable, :facetable
    end

    property :rights_holder, predicate: RDF::Vocab::DC.rightsHolder, class_name: Oargun::ControlledVocabularies::Creator do |index|
      index.as :symbol
    end

    property :copyright_status, predicate: RDF::Vocab::PREMIS.hasCopyrightStatus, class_name: Oargun::ControlledVocabularies::CopyrightStatus do |index|
      index.as :stored_searchable
    end

    validates_vocabulary_of :copyright_status

    property :license, predicate: RDF::Vocab::DC.rights, class_name: Oargun::ControlledVocabularies::RightsStatement do |index|
      index.as :stored_searchable
    end

    validates_vocabulary_of :license

    property :work_type, predicate: RDF::Vocab::DC.type, class_name: Oargun::ControlledVocabularies::ResourceType do |index|
      index.as :stored_searchable, :facetable
    end
    validates_vocabulary_of :work_type

    property :series_name, predicate: RDF::URI('http://opaquenamespace.org/ns/seriesName') do |index|
      index.as :displayable
    end

    # Dates
    property :created, predicate: RDF::Vocab::DC.created, class_name: 'TimeSpan'
    property :date_other, predicate: RDF::Vocab::DC.date, class_name: 'TimeSpan'
    property :date_valid, predicate: RDF::Vocab::DC.valid, class_name: 'TimeSpan'

    # RDA
    property :form_of_work, predicate: RDF::URI('http://www.rdaregistry.info/Elements/w/#formOfWork.en'),
                            class_name: Oargun::ControlledVocabularies::WorkType do |index|
      index.as :stored_searchable, :facetable
    end

    property :citation, predicate: RDF::URI('http://www.rdaregistry.info/Elements/u/#preferredCitation.en')

    # MODS
    property :digital_origin, predicate: RDF::Vocab::MODS.digitalOrigin do |index|
      index.as :stored_searchable
    end

    property :description_standard, predicate: RDF::Vocab::MODS.recordDescriptionStandard

    property :extent, predicate: RDF::Vocab::DC.extent do |index|
      index.as :searchable, :displayable
    end

    property :sub_location, predicate: RDF::Vocab::MODS.locationCopySublocation do |index|
      index.as :displayable
    end

    property :record_origin, predicate: RDF::Vocab::MODS.recordOrigin

    property :restrictions, predicate: RDF::Vocab::MODS.accessCondition do |index|
      index.as :stored_searchable
    end

    property :finding_aid, predicate: RDF::URI('http://lod.xdams.org/reload/oad/has_findingAid') do |index|
      index.as :stored_searchable
    end

    property :notes, predicate: RDF::Vocab::MODS.note, class_name: 'Note'

    def self.contributor_fields
      RELATIONS.keys
    end

    belongs_to :admin_policy, class_name: 'Hydra::AdminPolicy', predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
  end

  # Override of CurationConcerns. Since we have admin_policy rather than users with edit permission
  def paranoid_permissions
    true
  end

  def controlled_properties
    @controlled_properties ||= self.class.properties.each_with_object([]) do |(key, value), arr|
      if value.class_name && value.class_name.include?(LinkedVocabs::Controlled)
        arr << key
      end
    end
  end

  def ark
    identifier.first
  end
end
