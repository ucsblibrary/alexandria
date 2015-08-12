namespace :marc do

  require 'httpclient'

  SRU_BASE= '/sba01pub?version=1.1&operation=searchRetrieve'
  BATCH_SIZE = 150

  desc 'Download MARC records from Pegasus'
  task :download => :environment do
    clnt = HTTPClient.new
    response = clnt.get( pegasus_doc_count )
    doc = Nokogiri::XML(response.body)
    etd_count = doc.xpath("//zs:numberOfRecords").text.to_i

    all_etds = Nokogiri::XML "<zs:searchRetrieveResponse xmlns:zs='http://www.loc.gov/zing/srw/'><zs:version>1.1</zs:version><zs:numberOfRecords>#{etd_count}</zs:numberOfRecords><zs:records></zs:records></zs:searchRetrieveResponse>"
    records_parent = all_etds.xpath("/zs:searchRetrieveResponse/zs:records").first

    next_record = 1
    while next_record < etd_count do
      response = clnt.get( pegasus_batch(next_record) )
      etd_batch = Nokogiri::XML( response.body )
      File.open(batch_name(next_record), 'w') do |f|
        f.write(response.body)
        puts "Wrote etds#{next_record}-#{next_record+BATCH_SIZE-1}.xml"
      end
      # rewrite_record_numbers(etd_batch, next_record)
      etd_batch.xpath("//zs:record").each {|node| node.parent=records_parent}
      next_record += BATCH_SIZE
    end

    File.open(  File.join(Settings.marc_directory,"all_etds.xml"), 'w') do |f|
      f.write(all_etds.to_xml)
      puts "Wrote all_etds.xml"
    end

  end

  def batch_name(start)
    File.join(Settings.marc_directory,"etds#{start}-#{start+BATCH_SIZE-1}.xml")
  end

  def pegasus_doc_count
    Settings.pegasus_path + SRU_BASE + "&maximumRecords=1&query=(marc.947.a=pqd)"
  end

  def pegasus_batch(start)
    Settings.pegasus_path + SRU_BASE + "&startRecord=#{start}&maximumRecords=#{BATCH_SIZE}&query=(marc.947.a=pqd)"
  end

end
