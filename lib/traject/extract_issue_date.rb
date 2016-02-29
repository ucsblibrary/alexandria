module ExtractIssueDate
  # @return [Hash] with keys for making a TimeSpan
  def extract_issue_date
    date_extractor = Traject::MarcExtractor.new('008[7-10]')
    lambda do |record, accumulator|
      date = date_extractor.extract(record).compact.first
      attrs = if date.last == 'u'
                start_date = date.tr('u', '0').to_i
                finish_date = start_date + 9
                { start: [start_date], start_qualifier: ['approximate'],
                  finish: [finish_date], finish_qualifier: ['approximate'] }
              else
                { start: date.to_i }
      end
      accumulator << attrs
    end
  end
end
