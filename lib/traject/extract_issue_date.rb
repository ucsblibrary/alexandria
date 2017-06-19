# frozen_string_literal: true

module ExtractIssueDate
  # @return [Hash] with keys for making a TimeSpan
  def extract_issue_date
    date_extractor = Traject::MarcExtractor.new("008[7-10]")
    label_extractor = Traject::MarcExtractor.new("260c:264|*1|c")

    lambda do |record, accumulator|
      attrs = create_attrs(date_extractor.extract(record).compact.first)

      label = label_extractor.extract(record).compact.first
      accumulator << attrs.merge(label: label)
    end
  end

  def create_attrs(date)
    return { start: date.to_i } unless date.last == "u"

    start_date = date.tr("u", "0").to_i
    finish_date = start_date + 9

    {
      start: [start_date],
      start_qualifier: ["approximate"],
      finish: [finish_date],
      finish_qualifier: ["approximate"],
    }
  end
end
