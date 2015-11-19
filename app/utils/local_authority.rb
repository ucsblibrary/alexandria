module LocalAuthority
  def self.local_name_models
    [Agent, Person, Group, Organization]
  end

  def self.local_subject_models
    [Topic]
  end

  # All types of local authorities
  def self.local_authority_models
    local_name_models + local_subject_models
  end

  # Input record should be ActiveFedora::Base or SolrDocument.
  def self.local_authority?(record, models = nil)
    klass = if record.is_a?(SolrDocument)
              record['active_fedora_model_ssi'].constantize
            else
              record.class
            end
    models ||= local_authority_models
    models.include?(klass)
  end

  def self.local_name_authority?(record)
    local_authority?(record, local_name_models)
  end

  def self.local_subject_authority?(record)
    local_authority?(record, local_subject_models)
  end
end
