# frozen_string_literal: true

module Record
  # This method finds all fedora records that have a reference to this
  # record in any metadata field.
  #
  # @param [ActiveFedora::Base] record
  # @return [Array]
  def self.references_for(record)
    conn = ActiveFedora::InboundRelationConnection.new(
      ActiveFedora.fedora.connection
    )

    res = Ldp::Resource::RdfSource.new conn, record.uri

    res.graph.query(object: record.uri).map do |statement|
      ActiveFedora::Base.uri_to_id(statement.subject)
    end
  end
end
