# frozen_string_literal: true

class Person < Agent
  # Override CC
  # https://github.com/projecthydra/curation_concerns/blob/5680a3317c14cca1928476c74a91a5dc6703feda/app/models/concerns/curation_concerns/work_behavior.rb#L33-L42
  def self._to_partial_path
    "catalog/document"
  end
end
