module ExtractFulltextLink
  def extract_fulltext_link
    extract856u = Traject::MarcExtractor.new('856u', separator: nil)
    lambda { |record, accumulator|
      accumulator << extract856u.extract(record).grep(/proquest/).first
    }
  end
end
