# frozen_string_literal: true

require "httpclient"
require "sru"

namespace :marc do
  BATCH_SIZE = 100

  desc "Download Wax Cylinder MARC records from SRU"
  task download_cylinders: :environment do
    get_marc_records(:cylinder)
  end

  desc "Download ETD MARC records from SRU"
  task download_etds: :environment do
    get_marc_records(:etd)
  end

  desc "Download the MARC record for a PID"
  task :ark, [:pid] => :environment do |_, args|
    marc = SRU.by_ark(args[:pid])
    if marc
      File.open(
        File.join(Settings.marc_directory, "#{args[:pid]}.xml"), "w"
      ) do |f|
        f.write marc
      end
    else
      $stderr.puts "ERROR: nothing found for #{args[:pid]}"
    end
  end

  def get_marc_records(record_type)
    doc = Nokogiri::XML(SRU.batch(type: record_type, max: 1))
    marc_count = doc.css("numberOfRecords").text.to_i

    puts "Downloading #{marc_count} #{record_type}s"

    all_marc = []
    next_record = 1
    while next_record < marc_count
      marc = SRU.batch(type: record_type, max: BATCH_SIZE, start: next_record)
      File.open(batch_name(next_record, record_type), "w") do |f|
        f.write marc
        puts "Wrote records #{next_record}-#{next_record + BATCH_SIZE - 1}.xml"
      end
      all_marc << SRU.strip(marc)
      next_record += BATCH_SIZE
    end

    File.open(File.join(Settings.marc_directory, "#{record_type}-metadata.xml"), "a") do |f|
      f.write SRU.wrap(all_marc)
      puts "Wrote #{record_type}-metadata.xml"
    end
  end

  def batch_name(start, type_of_record)
    File.join(
      Settings.marc_directory,
      format("%s-%05d-%05d.xml",
             type_of_record,
             start,
             (start + BATCH_SIZE - 1))
    )
  end
end
