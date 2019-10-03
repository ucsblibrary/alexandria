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

  # FIXME: what on earth is happening here
  # @param [Nokogiri::XML]
  def self.embargo_attributes(xml)
    embargo_xpaths.inject({}) do |attrs, (field, xpath)|
      element = xml.xpath(xpath)
      value = element.text
      value = nil if value.blank?
      attrs.merge(field => value)
    end
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

  # @return [Hash]
  def self.descriptive_attributes(xml)
    attributes(xml).except(*embargo_xpaths.keys)
  end

  def self.metadata_attribs(xml)
    {
      title: [title(xml)],
      description: description(xml),
      controbutors: controbutors(xml),
      created_attributes: [{start: issued(xml)}],
      dissertation_degree: dissertation_degree(xml),
      dissertation_year: dissertation_year(xml),
      dissertation_institution: dissertation_institution(xml),
      issued: issued(xml),
      marc_subjects: marc_subjects(xml),
      keywords: keywords(xml),
      place_of_publication: ["[Santa Barbara, Calif.]"],
      publisher: ["University of California, Santa Barbara"],
      work_type: [{ _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/txt"] }],
      language: language(xml)
    }
  end

  def self.title(xml)
    xml.xpath("//DISS_title").text
  end

  def self.description(xml)
    arr = []
    xml.xpath("//DISS_abstract//DISS_para").each { |c| arr << c.text }
    arr.map { |a| CGI.unescape(CGI.unescape(a)) }
    [arr.join("\\n\\n")]
  end

  def controbutors(xml)
    [{
      author: [author],
      degree_grantor: [degree_grantor],
      degree_supervisor: [degree_supervisor]
    }]
  end

  def self.author(xml)
    # <DISS_surname>,[space]<DISS_fname>[space]<DISS_middle>.
    # If <DISS_middle> value is null, <DISS_surname>,[space]<DISS_fname>
    path = xml.xpath('//DISS_author[@type="primary"]/DISS_name')
    return [] if path.blank?
    name = [path.xpath("DISS_surname").text, path.xpath("DISS_fname").text,
            path.xpath("DISS_middle").text].join(" ")
    {type: "agent", name: name}
  end

  def self.degree_grantor(xml)
    # <DISS_inst_name>.[space]<DISS_inst_contact>
    name = [xml.xpath("//DISS_institution//DISS_inst_name").text,
             xml.xpath("//DISS_institution//DISS_inst_contact").text].join(".")
    {type: "organization", name: name}
  end

  def self.degree_supervisor(xml)
    name = [xml.xpath("//DISS_advisor//DISS_surname").text,
            xml.xpath("//DISS_advisor//DISS_fname").text].join(" ")
    middle = xml.xpath("//DISS_advisor//DISS_middle").text
    name = name + ' ' + middle unless middle.blank?
    {type: "agent", name: name}
  end

  def self.dissertation_degree(xml)
    [xml.xpath("//DISS_degree").text]
  end

  def self.dissertation_year(xml)
    issued(xml)
  end

  def self.dissertation_institution(xml)
    [xml.xpath("//DISS_dates//DISS_inst_name").text]
  end

  def self.issued(xml)
    [xml.xpath("//DISS_dates//DISS_comp_date").text]
  end

  def self.keywords(xml)
    xml.xpath("//DISS_keyword").text.split(",")
  end

  def self.marc_subjects(xml)
    xml.xpath("//DISS_categorization//DISS_category//DISS_cat_desc").children.map {|c| c.text}
  end

  def self.language(xml)
    if xml.xpath("//DISS_language").text.present?
      [Iso639[xml.xpath("//DISS_language").text].english_name]
    else
      []
    end
  end
end

