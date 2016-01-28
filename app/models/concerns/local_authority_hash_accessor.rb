module LocalAuthorityHashAccessor
  extend ActiveSupport::Concern

  # Override the hash accessor to cast local objects to AF::Base
  # TODO move this into Oargun using the casting functionality of ActiveTriples
  def [](arg)
    reflection = self.class.reflect_on_association(arg.to_sym)
    # Checking this avoids setting properties like head_id (belongs_to) to an array
    if (reflection && reflection.collection?) || !reflection
      Array(super).map do |item|
        if local_object?(item)
          ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(item.rdf_subject))
        else
          item
        end
      end
    else
      super
    end
  end

  private

    # @param [ActiveTriples::Resource] item
    # @returns true if the target is a local authority record
    def local_object?(item)
      item.respond_to?(:rdf_subject) &&
      item.rdf_subject.is_a?(RDF::URI) &&
      item.rdf_subject.start_with?(ActiveFedora.fedora.host) &&
      # item.class.include?(LinkedVocabs::Controlled) # TODO this could replace the last term
      (item.is_a?(Oargun::ControlledVocabularies::Creator) ||
       item.is_a?(Oargun::ControlledVocabularies::Subject))
    end
end
