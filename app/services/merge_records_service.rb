# frozen_string_literal: true

class MergeRecordsService
  # This service is intended to merge duplicate records.
  #
  # Example:
  #     old_reference:  Person.where(name: "Joel Conway").first
  #     new_reference:  Person.where(name: "Conway, Joel").first
  #
  # In this example, the service will find all objects with
  # references to "Joel Conway", and replace those references
  # with "Conway, Joel", and then delete the duplicate record,
  # "Joel Conway".

  attr_reader :old_reference, :new_reference

  def initialize(old_reference, new_reference)
    @old_reference = old_reference
    @new_reference = new_reference
    validate_records_are_local_authorities
    validate_compatible_merge
    validate_records_are_different
  end

  def run
    update_records_with_new_reference
    old_reference.destroy
  end

  private

    # Currently the only types of records we are allowed to merge
    # are local authority records.
    def validate_records_are_local_authorities
      return if [old_reference, new_reference].all? do |ref|
        LocalAuthority.local_authority?(ref)
      end

      raise IncompatibleMergeError,
            "Error: Cannot merge records that are not local authority records."
    end

    # Make sure these 2 type of records can be merged.
    # Local names can be merged with other local names because
    # they are referenced by the same metadata properties.
    # Example: The copyright holder of an Image could be a Person
    # or an Organization (both local names), but it can't be a
    # Topic or an Image record.
    # Local subjects can be merged with other local subjects for
    # the same reason.
    def validate_compatible_merge
      both_local_names = [old_reference, new_reference].all? do |ref|
        LocalAuthority.local_name_authority?(ref)
      end

      both_local_subjects = [old_reference, new_reference].all? do |ref|
        LocalAuthority.local_subject_authority?(ref)
      end

      return if both_local_names || both_local_subjects

      raise IncompatibleMergeError,
            "Error: Cannot merge records "\
            "that are not the same type of local authority."
    end

    def validate_records_are_different
      return unless new_reference == old_reference

      raise IncompatibleMergeError, "Error: Cannot merge a record with itself."
    end

    # Find all the records that refer to old_reference
    # @return [Array<String>] a list of ids
    def records_with_references
      Record.references_for(old_reference).uniq
    end

    def update_records_with_new_reference
      records_with_references.each do |id|
        record = ActiveFedora::Base.find(id)

        attributes = record.attributes.map do |key, val|
          values = Array(val).map do |zorp|
            # All of our {Agent}s ({Person}, etc.) are indexed in Solr
            # as {ControlledVocabularies::Creator},
            # {ControlledVocabularies::Subject} etc.  When we need to
            # modify the actual Fedora record, therefore, there's this
            # little dance where we convert the RDF object back into
            # an {ActiveFedora::Base} object
            if LocalAuthority.local_object? zorp
              LocalAuthority.rdf_to_fedora(zorp)
            else
              zorp
            end
          end

          { key => values } if Array(values).include?(old_reference)
        end.compact

        attributes.each do |hash|
          attr_name = hash.keys.first

          hash.values.each do |value|
            value.delete(old_reference)
            new_value = value + [new_reference]
            record.send("#{attr_name}=", new_value)
          end
        end

        record.save!
      end
    end
end
