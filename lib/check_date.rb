# frozen_string_literal: true

require "csv"
require "date"

module CheckDate
  CSV_COLUMNS = [
    :issued_start,
    :issued_finish,
    :created_start,
    :created_finish,
    :date_other_start,
    :date_other_finish,
  ].freeze

  # @param [String] file The path to the file
  # @return [Array<InvalidDate>]
  def self.csv(file)
    CSV.table(file, encoding: "bom|UTF-8").map.with_index do |row, i|
      CSV_COLUMNS.map do |col|
        next if row[col].nil?

        begin
          DateTime.strptime(row[col].to_s, template(row[col]))
        rescue ArgumentError, InvalidDate
          InvalidDate.new(
            "#{file}:\n"\
            "  '#{col}' in row #{i}: "\
            "\033[1;39m#{row[col]}\033[0m is not W3C-valid\n"\
            "    (https://www.w3.org/TR/1998/NOTE-datetime-19980827)."
          )
        end
      end
    end.flatten.compact.select { |r| r.is_a? InvalidDate }
  end

  # https://www.w3.org/TR/1998/NOTE-datetime-19980827
  # https://ruby-doc.org/core-2.2.0/Time.html#method-i-strftime
  #
  # @param [#to_s] date
  # @return [Date]
  def self.template(date)
    case date.to_s.length
    when 4
      "%Y"
    when 7
      "%Y-%m"
    when 10
      "%F"
    when 22
      "%FT%R%:z"
    when 25
      "%FT%T%:z"
    when 28
      "%FT%T.%L%:z"
    else
      raise InvalidDate
    end
  end
end
