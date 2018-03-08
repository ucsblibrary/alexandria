# frozen_string_literal: true

require "net/http"
require "uri"
##
# This class sends a PDF IO object to the Solr text extraction service
# and retrieves the JSON that is returned by Solr
class FullTextExtractor
  # @return [String] The text extracted from the PDF
  attr_reader :text

  # Initilize with PDF IO and send to the solr extract
  # service
  # @param file [IO]
  def initialize(file)
    uri =  URI(ActiveFedora::SolrService.instance.conn.uri +
               "update/extract?extractOnly=true&wt=json&extractFormat=text")

    http = Net::HTTP.start(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri)
    req.body = file
    req.add_field("Content-Type", "application/pdf")
    req.add_field("enctype", "multipart/form-data")
    @text = http.request(req).body.as_json.strip.force_encoding("UTF-8")
  end
end
