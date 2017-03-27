# frozen_string_literal: true

# Europeana rights statements are not returning labels,
# this puts a valid label into Marmotta so we don't hit
# Europeana multiple times without effect.
stmt = ControlledVocabularies::RightsStatement.new("http://www.europeana.eu/rights/unknown/")
stmt << RDF::Statement.new(stmt.rdf_subject, RDF::RDFS.label, "Unknown copyright status")
stmt.persist!
