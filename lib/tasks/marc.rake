# frozen_string_literal: true

require "httpclient"
require "sru"

namespace :marc do
  BATCH_SIZE = 100

  desc "Download Wax Cylinder MARC records from SRU"
  task download_cylinders: :environment do
    download_cylinders
  end

  desc "Download ETD MARC records from SRU"
  task download_etds: :environment do
    download_etds
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

  def download_etds
    start_doc = SRU.fetch(query: SRU.config[:etd_query])
    marc_count = Nokogiri::XML(start_doc).css("numberOfRecords").text.to_i
    puts "Downloading #{marc_count} ETDs"

    all_marc = []
    next_record = 1
    while next_record < marc_count
      marc = SRU.fetch(query: SRU.config[:etd_query],
                       max: BATCH_SIZE,
                       start: next_record)

      File.open(batch_name(next_record, record_type), "w") do |f|
        f.write marc
        puts "Wrote records #{next_record}-#{next_record + BATCH_SIZE - 1}.xml"
      end
      all_marc << SRU.strip(marc)
      next_record += BATCH_SIZE
    end

    File.open(
      File.join(Settings.marc_directory, "etd-metadata.xml"), "a"
    ) do |f|
      f.write SRU.wrap(all_marc)
      puts "Wrote etd-metadata.xml"
    end
  end

  # @param [Symbol] record_type Either :etd or :cylinder
  def download_cylinders
    start_doc =
      SRU.fetch(
        query: "(alma.all_for_ui=http://www.library.ucsb.edu/OBJID/Cylinder*)"
      )

    marc_count = Nokogiri::XML(start_doc).css("numberOfRecords").text.to_i
    puts "Downloading #{marc_count} cylinders (this is slow)"

    all_marc = []
    marc_count.times do |i|
      marc = SRU.fetch(
        # left-pad the cylinder number with zeros when smaller than 4
        # digits
        query: format(SRU.config[:cylinder_query], number: i.to_s.rjust(4, "0"))
      )

      next if Nokogiri::XML(marc).css("numberOfRecords").text == "0"

      dest = File.join(Settings.marc_directory, "cylinder-#{i}.xml")

      File.open(dest, "w") do |f|
        f.write marc
        puts "Wrote #{dest}"
      end
      all_marc << SRU.strip(marc)
    end

    File.open(
      File.join(Settings.marc_directory, "cylinder-metadata.xml"), "a"
    ) do |f|
      f.write SRU.wrap(all_marc.uniq)
      puts "Wrote cylinder-metadata.xml"
    end
  end

  # @param [Int] start
  # @param [Symbol] type_of_record Either :etd or :cylinder
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
