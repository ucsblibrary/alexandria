# frozen_string_literal: true

# This service assumes that the metadata file from ProQuest
# has already been attached to the ETD record.  It will read
# that file and update the ETD's metadata accordingly.
#
# The rules for setting embargo metadata came from this page:
# https://wiki.library.ucsb.edu/pages/viewpage.action?title=ETD+Sample+Files+for+DCE&spaceKey=repos
class Proquest::Metadata
  attr_reader :etd

  def initialize(etd)
    @etd = etd
  end

  def run
    if attributes.blank?
      $stderr.puts "ProQuest metadata not found for ETD: #{etd.id}"
    else
      update_embargo_metadata!
      update_access_metadata
    end
  end

  def attributes
    return @attributes if @attributes
    @attributes = Proquest::XML.attributes(Nokogiri::XML(etd.proquest.content))
    @attributes = {} if @attributes.values.all?(&:blank?)
    @attributes
  end

  def embargo_start_date
    if attributes[:DISS_agreement_decision_date].blank?
      transformed_start_date
    else
      Date.parse(attributes[:DISS_agreement_decision_date])
    end
  end

  # @return [Nil, Date] the date of the embargo end-date, or nil if no
  #   embargo or permanent embargo
  def embargo_release_date
    @embargo_end ||= parse_embargo
  end

  def policy_during_embargo
    AdminPolicy::DISCOVERY_POLICY_ID
  end

  def policy_after_embargo
    @policy_after_embargo ||= if attributes[:DISS_access_option].present?
                                parse_access_option
                              elsif batch_3?
                                AdminPolicy::PUBLIC_CAMPUS_POLICY_ID
                              end
  end

  private

    def update_embargo_metadata!
      return if no_embargo? || infinite_embargo?

      etd.embargo_release_date = embargo_release_date

      etd.visibility_during_embargo = RDF::URI(ActiveFedora::Base.id_to_uri(policy_during_embargo))
      etd.visibility_after_embargo  = RDF::URI(ActiveFedora::Base.id_to_uri(policy_after_embargo)) if policy_after_embargo

      etd.embargo.save!
    end

    def update_access_metadata
      etd.admin_policy_id =
        if embargo_release_date == :no_embargo
          policy_after_embargo
        else
          policy_during_embargo
        end
      etd.file_sets.each do |fs|
        fs.admin_policy_id = etd.admin_policy_id
        fs.save!
      end
    end

    def no_embargo?
      embargo_release_date == :no_embargo
    end

    def infinite_embargo?
      embargo_release_date == :infinite_embargo
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
    #
    # @return [Date, Nil]
    def transformed_start_date
      return if attributes[:DISS_accept_date].blank?

      date = Date.parse(attributes[:DISS_accept_date])
      if date.month == 1 && date.day == 1
        date = Date.parse("#{date.year}-12-31")
      end
      date
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
    #
    # If the field DISS_agreement_decision_date is blank, that means
    # this is a pre-Spring 2014 ETD without the ADRL-specific embargo
    # metadata; see
    # https://wiki.library.ucsb.edu/display/repos/ETD+Sample+Files+for+DCE.
    # In that case, parse the ProQuest embargo code.  If there is an
    # DISS_agreement_decision_date, calculate the embargo by comparing
    # the agreement date with the delayed release date.
    #
    # See also https://help.library.ucsb.edu/browse/DIGREPO-466
    #
    # @return [Date, Symbol] the date of the embargo release, or
    #   :no_embargo or :infinite_embargo if no release date
    def parse_embargo
      if attributes[:DISS_agreement_decision_date].blank?
        case attributes[:embargo_code]
        when "1"
          six_month_embargo
        when "2"
          one_year_embargo
        when "3"
          two_year_embargo
        when "4"
          return :infinite_embargo if attributes[:embargo_remove_date].nil?
          Date.parse(attributes[:embargo_remove_date])
        else
          :no_embargo
        end

      else
        case attributes[:DISS_delayed_release]
        when lambda { |release| release.blank? }
          :no_embargo
        when "never deliver"
          :infinite_embargo
        when /^.*2\s*year.*\Z/i
          two_year_embargo
        when /^.*1\s*year.*\Z/i
          one_year_embargo
        when /^.*6\s*month.*\Z/i
          six_month_embargo
        else
          Date.parse(attributes[:DISS_delayed_release])
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

    # ETDs submitted between Fall 2011 and Winter 2014 are in batch
    # #3.  See this page for the batch descriptions:
    # https://wiki.library.ucsb.edu/pages/viewpage.action?title=ETD+Sample+Files+for+DCE&spaceKey=repos
    def batch_3?
      attributes[:DISS_agreement_decision_date].nil?
    end
end
