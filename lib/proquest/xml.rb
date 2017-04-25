# frozen_string_literal: true

# Parse an XML metadata file from the ProQuest system, and
# collect all the interesting values in the attributes hash.

module Proquest::XML
  # @param [Nokogiri::XML]
  def self.attributes(xml)
    embargo_attributes(xml).merge(
      rights_holder: rights_holder(xml),
      date_copyrighted: date_copyrighted(xml)
    )
  end

  # @return [Hash]
  def self.descriptive_attributes(xml)
    attributes(xml).except(*embargo_xpaths.keys)
  end

  def self.embargo_xpaths
    {
      embargo_code: "DISS_submission/@embargo_code",
      DISS_accept_date: "//DISS_accept_date",
      DISS_agreement_decision_date: "//DISS_agreement_decision_date",
      DISS_delayed_release: "//DISS_delayed_release",
      DISS_access_option: "//DISS_access_option",
      embargo_remove_date: "//DISS_sales_restriction/@remove",
    }
  end

  # @param [Nokogiri::XML]
  def self.rights_holder(xml)
    path = xml.xpath('//DISS_author[@type="primary"]/DISS_name')
    return if path.blank?
    [[path.xpath("DISS_fname").text, path.xpath("DISS_surname").text].join(" ")]
  end

  # @param [Nokogiri::XML]
  def self.date_copyrighted(xml)
    sdate = xml.xpath("//DISS_dates/DISS_accept_date").text
    [Date.parse(sdate).year] if sdate.present?
  end

  # FIXME: what on earth is happening here
  #
  # @param [Nokogiri::XML]
  def self.embargo_attributes(xml)
    embargo_xpaths.inject({}) do |attrs, (field, xpath)|
      element = xml.xpath(xpath)
      value = element.text
      value = nil if value.blank?
      attrs.merge(field => value)
    end
  end
end
