# frozen_string_literal: true

##
# a job class that will update a Solr document
# with the extracted text of  attached PDFs
class FullTextToSolrJob < ApplicationJob
  # @return [String] the id for the SolrDocument being updated
  # @return [IO] the PDF content
  attr_reader :work_id

  queue_as :default

  def initialize(work_id)
    @work_id = work_id
  end

  def perform
    solr = RSolr.connect(url: ActiveFedora::SolrService.instance.conn.uri.to_s)
    solr_document = SolrDocument.find(@work_id).to_h
    solr_document["all_text_timv"] = all_text
    solr.add(solr_document)
    solr.commit
  end

  private

    def files
      ActiveFedora::Base.find(@work_id).file_sets.map(&:files).flatten
    end

    def all_text
      files.map { |file| FullTextExtractor.new(file.content).text }.join("")
    end
end
