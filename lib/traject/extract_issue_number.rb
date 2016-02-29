module ExtractIssueNumber
  # Transform field 028 with "0" in the indicator1 field.
  # Format "$b : $a"
  def extract_issue_number
    a_extractor = Traject::MarcExtractor.new('028|0*|a')
    b_extractor = Traject::MarcExtractor.new('028|0*|b')
    lambda do |record, accumulator|
      a_field = a_extractor.extract(record).compact.first
      b_field = b_extractor.extract(record).compact.first
      accumulator << "#{b_field} : #{a_field}"
    end
  end
end


