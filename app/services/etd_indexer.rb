class ETDIndexer < ObjectIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('generic_file_ids', :symbol)] = object.generic_file_ids
    end
  end
end
