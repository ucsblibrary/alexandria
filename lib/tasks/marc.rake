namespace :marc do
  require 'httpclient'

  SRU_BASE = '/sba01pub?version=1.1&operation=searchRetrieve'.freeze
  BATCH_SIZE = 100

  desc 'Download Wax Cylinder MARC records from Pegasus'
  task download_cylinders: :environment do
    get_marc_records('cylinders', '&query=(dc.format=wd)')
  end

  desc 'Download ETD MARC records from Pegasus'
  task download_etds: :environment do
    get_marc_records('etds', '&query=(marc.947.a=pqd)')
  end

  def get_marc_records(record_type, record_filter)
    clnt = HTTPClient.new
    response = clnt.get(pegasus_doc_count(record_filter))
    doc = Nokogiri::XML(response.body)
    marc_count = doc.xpath('//zs:numberOfRecords').text.to_i

    puts "Downloading #{marc_count} #{record_type}"

    marc_records = Nokogiri::XML "<zs:searchRetrieveResponse xmlns:zs='http://www.loc.gov/zing/srw/'><zs:version>1.1</zs:version><zs:numberOfRecords>#{marc_count}</zs:numberOfRecords><zs:records></zs:records></zs:searchRetrieveResponse>"
    records_parent = marc_records.xpath('/zs:searchRetrieveResponse/zs:records').first

    next_record = 1
    while next_record < marc_count
      response = clnt.get(pegasus_batch_url(next_record, record_filter))
      marc_batch = Nokogiri::XML(response.body)
      File.open(batch_name(next_record, record_type), 'w') do |f|
        f.write(response.body)
        puts "Wrote records #{next_record}-#{next_record + BATCH_SIZE - 1}.xml"
      end
      marc_batch.xpath('//zs:record').each { |node| node.parent = records_parent }
      next_record += BATCH_SIZE
    end

    File.open(File.join(Settings.marc_directory, "#{record_type}-metadata.xml"), 'w') do |f|
      f.write(marc_records.to_xml)
      puts "Wrote #{record_type}-metadata.xml"
    end
  end

  def batch_name(start, type_of_record)
    File.join(Settings.marc_directory, "%s-%05d-%05d.xml" % [type_of_record, start, start + BATCH_SIZE - 1])
  end

  def pegasus_doc_count(query)
    Settings.pegasus_path + SRU_BASE + query + '&maximumRecords=1'
  end

  def pegasus_batch_url(start, query)
    Settings.pegasus_path + SRU_BASE + query + "&startRecord=#{start}&maximumRecords=#{BATCH_SIZE}"
  end
end
