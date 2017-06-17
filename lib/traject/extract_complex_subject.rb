# frozen_string_literal: true

module ExtractComplexSubject
  # Transform fields 650 and 651 that have "0" in the indicator2
  # field.  Concatenate sub-fields with a double-dash.

  def extract_complex_subject
    separator = " -- "
    extractor = Traject::MarcExtractor.new("650|*0|axvyz:651|*0|axvyz",
                                           separator: separator)
    lambda do |record, accumulator|
      fields = extractor.extract(record).compact

      fields = fields.map do |field|
        Traject::Macros::Marc21.trim_punctuation(field)
      end

      fields.each { |field| accumulator << field }
    end
  end
end
