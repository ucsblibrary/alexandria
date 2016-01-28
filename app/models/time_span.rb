class TimeSpan < ActiveTriples::Resource
  property :start, predicate: ::RDF::Vocab::EDM.begin
  property :finish, predicate: ::RDF::Vocab::EDM.end
  property :start_qualifier, predicate: ::RDF::Vocab::CRM.P79_beginning_is_qualified_by
  property :finish_qualifier, predicate: ::RDF::Vocab::CRM.P80_end_is_qualified_by
  property :label, predicate: ::RDF::SKOS.prefLabel
  property :note, predicate: ::RDF::SKOS.note

  def initialize(uri=RDF::Node.new, parent=nil)
    uri = if uri.try(:node?)
      RDF::URI("#timespan_#{uri.to_s.gsub('_:','')}")
    elsif uri.to_s.include?("#")
      RDF::URI(uri)
    end
    super
  end

  def final_parent
    parent
  end

  def persisted?
    type.include?(RDF::URI("http://fedora.info/definitions/v4/repository#Resource"))
  end

  def new_record?
    !persisted?
  end

  # MODS date qualifiers
  APPROX = 'approximate'
  INFERRED = 'inferred'
  QUESTIONABLE = 'questionable'

  QUALIFIERS = [APPROX, INFERRED, QUESTIONABLE]

  def self.qualifiers
    QUALIFIERS
  end

  def range?
    start.any?(&:present?) && finish.any?(&:present?)
  end

  # def node?
  #  false
  # end

  # Return a string for display of this record
  def display_label
    if label.present?
      label.first
    else
      start_string = qualified_date(start, start_qualifier)
      finish_string = qualified_date(finish, finish_qualifier)
      [start_string, finish_string].compact.join(' - ')
    end
  end

  def qualified_date(date, qualifier)
    if qualifier.include?(APPROX) || qualifier.include?(QUESTIONABLE)
      "ca. #{date.first}"
    else
      date.first
    end
  end

  # Return an array of years, for faceting in Solr.
  def to_a
    if range?
      (start_integer..finish_integer).to_a
    else
      start_integer
    end
  end

  def earliest_year
    start.reject(&:blank?).sort { |a, b| extract_year(a) <=> extract_year(b) }.first
  end

  private

    def start_integer
      extract_year(start.first)
    end

    def finish_integer
      extract_year(finish.first)
    end

    def extract_year(date)
      DateUtil.extract_year(date)
    end
end
