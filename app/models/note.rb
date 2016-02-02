class Note < ActiveTriples::Resource
  include StoredInline

  property :value, predicate: ::RDF::Vocab::MODS.noteGroupValue
  property :note_type, predicate: ::RDF::Vocab::MODS.noteGroupType
end
