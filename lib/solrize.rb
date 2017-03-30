# frozen_string_literal: true

module Solrize
  def solrize
    return super if node?
    return [rdf_subject.to_s] if rdf_label.first.to_s.blank? || rdf_label.first.to_s == rdf_subject.to_s
    [rdf_subject.to_s, { label: "#{rdf_label.first}$#{rdf_subject}" }]
  end
end