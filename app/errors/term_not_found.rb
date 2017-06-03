# frozen_string_literal: true

# Raised when we are unable to find a registered vocabulary term for a
# given RDF URI
class TermNotFound < StandardError; end
