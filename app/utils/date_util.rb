module DateUtil
  def self.extract_year(date)
    date = date.to_s
    if date.blank?
      nil
    elsif /^\d{4}$/ =~ date
      # Date.iso8601 doesn't support YYYY dates
      date.to_i
    else
      Date.iso8601(date).year
    end
  rescue ArgumentError
    raise "Invalid date: #{date.inspect} in #{inspect}"
  end
end
