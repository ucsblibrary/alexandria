# frozen_string_literal: true

# Metadata fields common to all objects
module Metadata
  extend ActiveSupport::Concern

  RELATIONS = {
    contributor: RDF::Vocab::DC.contributor,
    creator:     RDF::Vocab::DC.creator,
  }.merge(::Fields::MARCREL)

  included do
    # For info about how local_collection_id is used, @see
    # {doc/local_collections.md}
    property :local_collection_id,
             predicate: RDF::URI(
               "http://opaquenamespace.org/ns/localCollectionID"
             ) do |index|

      index.as :symbol
    end

    # Attach an object to its parent, following the same pattern we
    # use for local_collection_id
    property :parent_id,
             predicate: Hydra::PCDM::Vocab::PCDMTerms.memberOf,
             multiple: false do |index|
      index.as :symbol
    end

    property :index_map_id,
             predicate: Hydra::PCDM::Vocab::PCDMTerms
               .hasRelatedObject do |index|
      index.as :symbol
    end

    # For ARKs
    property :identifier, predicate: RDF::Vocab::DC.identifier do |index|
      index.as :displayable
    end

    # For Merritt ARKs
    property :merritt_id, predicate: RDF::Vocab::DC11.identifier do |index|
      index.as :displayable, :stored_searchable
    end

    property :accession_number,
             predicate: RDF::URI(
               "http://opaquenamespace.org/ns/cco/accessionNumber"
             ) do |index|
      # symbol is needed for exact match search in the
      # CollectionFactory
      index.as :symbol, :stored_searchable, :sortable
    end

    property :alternative, predicate: RDF::Vocab::DC.alternative do |index|
      index.as :stored_searchable
    end

    RELATIONS.each do |field_name, predicate|
      property field_name,
               predicate: predicate,
               class_name: ControlledVocabularies::Creator do |index|
        index.as :stored_searchable, :facetable
      end
    end

    property :description, predicate: RDF::Vocab::DC.description do |index|
      index.as :stored_searchable
    end

    # Spatial
    property :latitude, predicate: RDF::Vocab::EXIF.gpsLatitude do |index|
      index.as :displayable
    end

    property :longitude, predicate: RDF::Vocab::EXIF.gpsLongitude do |index|
      index.as :displayable
    end

    # rubocop:disable Metrics/LineLength
    property :scale,
             predicate: RDF::URI("http://www.rdaregistry.info/Elements/u/#horizontalScaleOfCartographicContent.en") do |index|

      index.as :stored_searchable
    end
    # rubocop:enable Metrics/LineLength

    # Defines the bounding box for the layer.
    # We always assert units of decimal degrees and EPSG:4326 projection.
    # @see http://dublincore.org/documents/dcmi-box/
    # @example
    #     object.coverage = "northlimit=43.039; eastlimit=-69.856; "\
    #                       "southlimit=42.943; westlimit=-71.032; "\
    #                       "units=degrees; projection=EPSG:4326"
    property :coverage, predicate: ::RDF::Vocab::DC11.coverage, multiple: false

    property :language, predicate: RDF::Vocab::DC.language,
                        class_name: ControlledVocabularies::Language do |index|
      index.as :displayable
    end

    property :location,
             predicate: RDF::Vocab::DC.spatial,
             class_name: ControlledVocabularies::Geographic do |index|
      index.as :stored_searchable, :facetable
    end

    property :place_of_publication,
             predicate: RDF::Vocab::MARCRelators.pup do |index|
      index.as :stored_searchable
    end

    property :lc_subject,
             predicate: RDF::Vocab::DC.subject,
             class_name: ControlledVocabularies::Subject do |index|
      index.as :stored_searchable, :facetable
    end

    validates_vocabulary_of :lc_subject

    property :institution,
             predicate: Vocabularies::OARGUN.contributingInstitution,
             class_name: ControlledVocabularies::Organization do |index|
      index.as :stored_searchable
    end

    validates_vocabulary_of :institution

    property :publisher, predicate: RDF::Vocab::DC.publisher do |index|
      index.as :stored_searchable, :facetable
    end

    property :rights_holder,
             predicate: RDF::Vocab::DC.rightsHolder,
             class_name: ControlledVocabularies::Creator do |index|
      index.as :symbol
    end

    property :copyright_status,
             predicate: RDF::Vocab::PREMIS.hasCopyrightStatus,
             class_name: ControlledVocabularies::CopyrightStatus do |index|
      index.as :stored_searchable
    end

    validates_vocabulary_of :copyright_status

    property :license,
             predicate: RDF::Vocab::DC.rights,
             class_name: ControlledVocabularies::RightsStatement do |index|
      index.as :stored_searchable, :facetable
    end

    validates_vocabulary_of :license

    property :work_type,
             predicate: RDF::Vocab::DC.type,
             class_name: ControlledVocabularies::ResourceType do |index|
      index.as :stored_searchable, :facetable
    end
    validates_vocabulary_of :work_type

    property :series_name,
             predicate: RDF::URI(
               "http://opaquenamespace.org/ns/seriesName"
             ) do |index|

      index.as :displayable, :facetable
    end

    property :table_of_contents,
             predicate: RDF::Vocab::DC.tableOfContents do |index|
      index.as :stored_searchable
    end

    property :edition, predicate: RDF::Vocab::MODS.edition do |index|
      index.as :stored_searchable
    end

    property :folder_name,
             predicate: RDF::URI(
               "http://opaquenamespace.org/ns/folderName"
             ) do |index|

      index.as :stored_searchable, :facetable
    end

    property :issue_number,
             predicate: RDF::URI(
               "http://id.loc.gov/vocabulary/identifiers/issue-number"
             ) do |index|

      index.as :stored_searchable
    end

    property :matrix_number,
             predicate: RDF::URI(
               "http://id.loc.gov/vocabulary/identifiers/matrix-number"
             ) do |index|

      index.as :stored_searchable
    end

    # Dates
    property :created, predicate: RDF::Vocab::DC.created, class_name: TimeSpan
    property :date_other, predicate: RDF::Vocab::DC.date, class_name: TimeSpan
    property :date_valid, predicate: RDF::Vocab::DC.valid, class_name: TimeSpan

    # RDA
    property :form_of_work,
             predicate: RDF::URI(
               "http://www.rdaregistry.info/Elements/w/#formOfWork.en"
             ),
             class_name: ControlledVocabularies::WorkType do |index|

      index.as :stored_searchable, :facetable
    end

    property :citation,
             predicate: RDF::URI(
               "http://www.rdaregistry.info/Elements/u/#preferredCitation.en"
             ) do |index|

      index.as :displayable
    end

    # MODS
    property :digital_origin,
             predicate: RDF::Vocab::MODS.digitalOrigin do |index|
      index.as :stored_searchable
    end

    property :description_standard,
             predicate: RDF::Vocab::MODS.recordDescriptionStandard

    property :extent, predicate: RDF::Vocab::DC.extent do |index|
      index.as :searchable, :displayable
    end

    property :sub_location,
             predicate: RDF::Vocab::MODS.locationCopySublocation do |index|
      index.as :displayable, :facetable
    end

    property :record_origin, predicate: RDF::Vocab::MODS.recordOrigin

    property :restrictions,
             predicate: RDF::Vocab::MODS.accessCondition do |index|
      index.as :stored_searchable
    end

    property :finding_aid,
             predicate: RDF::URI(
               "http://lod.xdams.org/reload/oad/has_findingAid"
             ) do |index|

      index.as :stored_searchable
    end

    property :notes, predicate: RDF::Vocab::MODS.note, class_name: "Note"

    def self.contributor_fields
      RELATIONS.keys
    end
  end

  # Override of CurationConcerns. Since we have admin_policy rather
  # than users with edit permission
  def paranoid_permissions
    true
  end

  def controlled_properties
    return @controlled_properties if @controlled_properties.present?

    props = self.class.properties

    @controlled_properties ||= props.each_with_object([]) do |(key, value), arr|
      next if value.class_name.nil?
      next unless value.class_name.include?(LinkedVocabs::Controlled)

      arr << key
    end
  end

  def ark
    identifier.first
  end
end
