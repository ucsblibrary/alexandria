# frozen_string_literal: true

##
# a job class that will update a Solr document
# with the extracted text of an attached PDF
class FullTextToSolrJob < ApplicationJob
  # @return [String] the id for the SolrDocument being updated
  # @return [IO] the PDF content
  attr_reader :solr_document_id, :work_content

  queue_as :default

  def initialize(solr_document_id, work_content)
    @solr_document_id = solr_document_id
    @work_content = work_content
  end

  def perform
    solr = RSolr.connect(url: ActiveFedora::SolrService.instance.conn.uri.to_s)
    solr_document = SolrDocument.find(@solr_document_id).to_h
    solr_document["all_text_timv"] = FullTextExtractor.new(@work_content).text
    solr.add(solr_document)
    solr.commit
  end
end
