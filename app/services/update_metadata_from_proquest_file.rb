require 'importer/proquest_xml_parser'

class UpdateMetadataFromProquestFile
  # This service assumes that the metadata file from ProQuest
  # has already been attached to the ETD record.  It will read
  # that file and update the ETD's metadata accordingly.

  # The rules for setting embargo metadata came from this page:
  # https://wiki.library.ucsb.edu/pages/viewpage.action?title=ETD+Sample+Files+for+DCE&spaceKey=repos

  attr_reader :etd

  def initialize(etd)
    @etd = etd
  end

  def run
    if attributes.blank?
      puts "ProQuest metadata not found for ETD: #{etd.id}"
    else
      update_embargo_metadata!
      update_access_metadata
      update_descriptive_metadata
    end
  end

  def attributes
    return @attributes if @attributes
    @attributes = ::Importer::ProquestXmlParser.new(etd.proquest.content).attributes
    @attributes = {} if @attributes.all? { |_k, v| v.blank? }
    @attributes
  end

  def embargo_start_date
    if attributes[:DISS_agreement_decision_date].blank?
      transformed_start_date
    else
      Date.parse(attributes[:DISS_agreement_decision_date])
    end
  end

  def embargo_release_date
    return @embargo_end if @embargo_end
    # If the field DISS_agreement_decision_date is blank, that means
    # this is a pre-Spring 2014 ETD without the ADRL-specific embargo
    # metadata; see
    # https://wiki.library.ucsb.edu/display/repos/ETD+Sample+Files+for+DCE.
    # In that case, parse the ProQuest embargo code.  If there is an
    # DISS_agreement_decision_date, calculate the embargo by comparing
    # the agreement date with the delayed release date.
    #
    # See also https://help.library.ucsb.edu/browse/DIGREPO-466
    @embargo_end = if attributes[:DISS_agreement_decision_date].blank?
                     parse_embargo_code
                   else
                     parse_delayed_release_date
                   end
  end

  def policy_during_embargo
    AdminPolicy::DISCOVERY_POLICY_ID
  end

  def policy_after_embargo
    return @policy_after_embargo if @policy_after_embargo
    @policy_after_embargo = if !attributes[:DISS_access_option].blank?
                              parse_access_option
                            elsif batch_3?
                              AdminPolicy::PUBLIC_CAMPUS_POLICY_ID
                            end
  end

  private

    def update_embargo_metadata!
      return if no_embargo?
      etd.embargo_release_date = embargo_release_date

      etd.visibility_during_embargo = RDF::URI(ActiveFedora::Base.id_to_uri(policy_during_embargo))
      etd.visibility_after_embargo  = RDF::URI(ActiveFedora::Base.id_to_uri(policy_after_embargo)) if policy_after_embargo

      etd.embargo.save!
    end

    def update_access_metadata
      etd.admin_policy_id =
        if etd.embargo_release_date || infinite_embargo?
          policy_during_embargo
        else
          policy_after_embargo
        end
    end

    def update_descriptive_metadata
      descriptive_attributes.each do |attr, val|
        etd[attr] = val
      end
    end

    def descriptive_attributes
      attributes.except(*Importer::ProquestXmlParser.embargo_xpaths.keys)
    end

    def no_embargo?
      attributes[:embargo_code] == '0' || embargo_release_date.blank?
    end

    def infinite_embargo?
      attributes[:embargo_code] == '4' && embargo_release_date.blank?
    end

    # The embargo release date for ETDs must be calculated based
    # on the DISS_accept_date element.  Unfortunately, according
    # to the ProQuest Reference Guide "ProQuest only tracks the
    # year that a submission was accepted but for internal
    # reasons this variable includes both month and day.  Every
    # submission will have January 1st for this variable."
    # Therefore, all DISS_accept_date with a value of 01/01/YYYY
    # for ETDs should be interpreted as 12/31/YYYY for purposes
    # of calculating the embargo release date.
    def transformed_start_date
      unless attributes[:DISS_accept_date].blank?
        date = Date.parse(attributes[:DISS_accept_date])
        if date.month == 1 && date.day == 1
          date = Date.parse("#{date.year}-12-31")
        end
        date
      end
    end

    def six_month_embargo
      embargo_start_date + 6.months
    end

    def one_year_embargo
      embargo_start_date + 1.year
    end

    def two_year_embargo
      embargo_start_date + 2.years
    end

    # Calculate the release date based on <DISS_delayed_release>
    def parse_delayed_release_date
      if attributes[:DISS_delayed_release].blank?
        nil
      elsif attributes[:DISS_delayed_release] =~ /^.*2\s*year.*\Z/i
        two_year_embargo
      elsif attributes[:DISS_delayed_release] =~ /^.*1\s*year.*\Z/i
        one_year_embargo
      elsif attributes[:DISS_delayed_release] =~ /^.*6\s*month.*\Z/i
        six_month_embargo
      else
        Date.parse(attributes[:DISS_delayed_release])
      end
    end

    # Calculate the release date based on <embargo_code>
    def parse_embargo_code
      case attributes[:embargo_code]
      when '1'
        six_month_embargo
      when '2'
        one_year_embargo
      when '3'
        two_year_embargo
      when '4'
        if attributes[:embargo_remove_date].blank?
          nil
        else
          Date.parse(attributes[:embargo_remove_date])
        end
      end
    end

    def parse_access_option
      if attributes[:DISS_access_option] =~ /^.*open access.*\Z/i
        AdminPolicy::PUBLIC_POLICY_ID
      elsif attributes[:DISS_access_option] =~ /^.*campus use.*\Z/i
        AdminPolicy::PUBLIC_CAMPUS_POLICY_ID
      else
        # If we can't figure out the correct policy,
        # set it to the most restrictive policy.
        AdminPolicy::RESTRICTED_POLICY_ID
      end
    end

    # ETDs submitted between Fall 2011 and Winter 2014 are in
    # batch #3.  See this page for the batch descriptions:
    # https://wiki.library.ucsb.edu/pages/viewpage.action?title=ETD+Sample+Files+for+DCE&spaceKey=repos
    def batch_3?
      attributes[:DISS_agreement_decision_date].nil?
    end
end
