# frozen_string_literal: true

module ExtractLCSubject
  def extract_lc_subject
    lambda do |record, accumulator|
      {
        "person" => Traject::MarcExtractor.new("600abcdq"),
        "organization" => Traject::MarcExtractor.new("610ab"),
        "topic" => Traject::MarcExtractor.new(
          "630a:650|*0|a:650|*0|x:650|*0|y:651|*0|x:651|*0|y"
        ),
      }.each do |k, v|
        names = v.extract(record).compact

        accumulator << (names.map do |n|
                          { type: k,
                            name: Traject::Macros::Marc21.trim_punctuation(n), }
                        end)

        accumulator.flatten!
      end
    end
  end
end
