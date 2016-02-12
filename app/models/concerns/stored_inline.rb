module StoredInline
  extend ActiveSupport::Concern

  def initialize(uri = RDF::Node.new, parent = nil)
    uri = if uri.try(:node?)
            RDF::URI("#timespan_#{uri.to_s.gsub('_:', '')}")
          elsif uri.to_s.include?('#')
            RDF::URI(uri)
    end
    super
  end

  def final_parent
    parent
  end

  def persisted?
    !new_record?
  end

  def new_record?
    id.start_with?('#')
  end
end
