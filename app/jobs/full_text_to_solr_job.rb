# frozen_string_literal: true

##
# a job class that will update a Solr document
# with the extracted text of  attached PDFs
class FullTextToSolrJob < ApplicationJob
  # @return [String] the id for the SolrDocument being updated
  # @return [IO] the PDF content
  attr_reader :work_id, :logger

  queue_as :default

  def initialize(work_id, logger = Logger.new(STDOUT))
    @work_id = work_id
    @logger = logger
  end

  def perform
    return if all_text.nil?
    solr_document = SolrDocument.find(@work_id).to_h
    solr_document["all_text_timv"] = all_text
    ActiveFedora::SolrService.add(solr_document)
    ActiveFedora::SolrService.commit
    @logger.info("Full text indexed for work: #{@work_id}")
  end

  private

    def files
      return nil if ActiveFedora::Base.find(@work_id).class == Collection
      ActiveFedora::Base.find(@work_id).file_sets.map(&:files).flatten
    end

    def all_text
      return nil if files.nil?
      files.map { |file| FullTextExtractor.new(file.content).text }.join("")
    end
end
