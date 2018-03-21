# frozen_string_literal: true

# Europeana rights statements are not returning labels,
# this puts a valid label into Marmotta so we don't hit
# Europeana multiple times without effect.

# This is preventing us from being able to deploy on AWS. Commenting it out
# until we're better able to debug.
# stmt = ControlledVocabularies::RightsStatement.new(
#   "http://www.europeana.eu/rights/unknown/"
# )
# 
# stmt << RDF::Statement.new(stmt.rdf_subject,
#                            RDF::RDFS.label, "Unknown copyright status")
# 
# stmt.persist!
