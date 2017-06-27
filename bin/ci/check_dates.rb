#!/usr/bin/env ruby
# frozen_string_literal: true

$stdout.sync = true # flush output immediately
require File.expand_path("../../../config/environment", __FILE__)

require "check_date"

errors = ARGV.map do |file|
  case File.extname(file)
  # when ".xml"
  # check_xml(file)
  when ".csv"
    CheckDate.csv(file)
  else
    raise ArgumentError, "Unsupported file type: #{file}"
  end
end.flatten

exit 0 if errors.empty?

errors.each do |err|
  $stderr.puts err.message
end

exit 1
