module ExtractMatrixNumber
  # Transform field 028 with "1" in the indicator1 field.
  # Format "$b : $a"
  def extract_matrix_number
    a_extractor = Traject::MarcExtractor.new('028|1*|a')
    b_extractor = Traject::MarcExtractor.new('028|1*|b')
    lambda do |record, accumulator|
      a_field = a_extractor.extract(record).compact.first
      b_field = b_extractor.extract(record).compact.first
      result = [b_field, a_field].compact
      accumulator << result.join(' : '.freeze) unless result.empty?
    end
  end
end
