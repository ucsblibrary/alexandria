# frozen_string_literal: true

##
# a job class that will update a Solr document
# with the extracted text of  attached PDFs
class FullTextToSolrJob < ApplicationJob
  # @return [String] the id for the SolrDocument being updated
  # @return [IO] the PDF content
  attr_reader :solr_doc

  queue_as :default

  def initialize(solr_doc)
    @solr_doc = solr_doc
  end

  def perform
    return if solr_doc[:id].blank?
    return if all_text.blank?

    solr_doc["all_text_timv"] = all_text
    ActiveFedora::SolrService.add(solr_doc)
    ActiveFedora::SolrService.commit
  end

  private

    def work
      ActiveFedora::Base.find(solr_doc[:id])
    end

    def files
      models = CurationConcerns.config.registered_curation_concern_types
      return nil unless models.include?(work.class.to_s)

      work.file_sets.map(&:files).flatten
    end

    def all_text
      return nil if files.nil?
      files.map { |file| FullTextExtractor.new(file.content).text }.join("")
    end
end
