# frozen_string_literal: true

module StoredInline
  extend ActiveSupport::Concern

  def initialize(uri = RDF::Node.new, _parent = ActiveTriples::Resource.new)
    uri = if uri.try(:node?)
            RDF::URI("#timespan_#{uri.to_s.gsub("_:", "")}")
          elsif uri.to_s.include?("#")
            RDF::URI(uri)
          end
    super
  end

  def persisted?
    !new_record?
  end

  def new_record?
    id.start_with?("#")
  end
end
