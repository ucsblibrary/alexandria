require 'rest_client'

module Oargun::ControlledVocabularies
  class Geographic < ActiveTriples::Resource
    include Oargun::RDF::Controlled

    configure :rdf_label => RDF::URI('http://www.geonames.org/ontology#name')
    use_vocabulary :geonames, class: Oargun::Vocabularies::GEONAMES
    use_vocabulary :lcnames, class: Oargun::Vocabularies::LCNAMES
    use_vocabulary :lcsh, class: Oargun::Vocabularies::LCSH

    property :geoname, :predicate => RDF::URI('http://www.geonames.org/ontology#name')
    property :latitude, :predicate => RDF::URI('http://www.w3.org/2003/01/geo/wgs84_pos#lat')
    property :longitude, :predicate => RDF::URI('http://www.w3.org/2003/01/geo/wgs84_pos#long')
    property :parentFeature, :predicate => RDF::URI('http://www.geonames.org/ontology#parentFeature'), :class_name => 'Oargun::ControlledVocabularies::Geographic'
    property :parentCountry, :predicate => RDF::URI('http://www.geonames.org/ontology#parentCountry'), :class_name => 'Oargun::ControlledVocabularies::Geographic'
    property :featureCode, :predicate => RDF::URI('http://www.geonames.org/ontology#featureCode')
    property :featureClass, :predicate => RDF::URI('http://www.geonames.org/ontology#featureClass')
    property :population, :predicate => RDF::URI('http://www.geonames.org/ontology#population')
    property :countryCode, :predicate => RDF::URI('http://www.geonames.org/ontology#countryCode')
    property :wikipedia, :predicate => RDF::URI('http://www.geonames.org/ontology#wikipediaArticle')

    ##
    # Overrides rdf_label to recursively add location disambiguation when available.
    def rdf_label
      label = super
      unless parentFeature.empty? or RDF::URI(label.first).valid?
        #TODO: Identify more featureCodes that should cause us to terminate the sequence
        return label if top_level_element?

        parent_label = (parentFeature.first.kind_of? ActiveTriples::Resource) ? parentFeature.first.rdf_label.first : []
        return label if parent_label.empty? or RDF::URI(parent_label).valid? or parent_label.starts_with? '_:'
        label = "#{label.first} >> #{parent_label}"
      end
      Array(label)
    end

    # Fetch parent features if they exist. Necessary for automatic population of rdf label.
    def fetch(*args)
      result = super
      return result if top_level_element?
      parentFeature.each do |feature|
        feature.fetch(*args)
      end
      result
    end

    # Persist parent features.
    def persist!
      result = super
      return result if top_level_element?
      parentFeature.each do |feature|
        feature.persist!
      end
      result
    end

    def top_level_element?
      featureCode = self.featureCode.first
      top_level_codes = [RDF::URI('http://www.geonames.org/ontology#A.PCLI')]
      featureCode.respond_to?(:rdf_subject) && top_level_codes.include?(featureCode.rdf_subject)
    end
  end
end
