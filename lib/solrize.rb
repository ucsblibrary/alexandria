# frozen_string_literal: true

module Solrize
  def solrize
    return super if node?

    label = rdf_label.first.to_s
    subject = rdf_subject.to_s

    [
      subject,
      ({ label: "#{label}$#{subject}" } unless label.blank? ||
                                               label == subject),
    ].compact
  end
end
