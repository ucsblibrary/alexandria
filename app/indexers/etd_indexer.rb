class ETDIndexer < ObjectIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('member_ids', :symbol)] = object.member_ids
      solr_doc[Solrizer.solr_name('copyright', :displayable)] = "#{object.rights_holder.first}, #{object.date_copyrighted.first}"

      solr_doc[Solrizer.solr_name('department', :facetable)] = department(solr_doc)
      solr_doc[Solrizer.solr_name('dissertation', :displayable)] = "#{object.dissertation_degree.first}--#{object.dissertation_institution.first}, #{object.dissertation_year.first}"
      solr_doc[Solrizer.solr_name('creator_label', :facetable)] = solr_doc[Solrizer.solr_name('author', :facetable)]
    end
  end

  private

    # Derive department by stripping "UC, SB" from the degree grantor field
    def department(solr_doc)
      Array(solr_doc[Solrizer.solr_name('degree_grantor', :symbol)])
        .map { |a| a.sub(/^University of California, Santa Barbara\. /, '') }
    end

    # Create a date field for sorting on
    def sortable_date
      if timespan?
        super
      else
        Array(sorted_key_date).first
      end
    end

    # Create a year field (integer, multiple) for faceting on
    def facetable_year
      if timespan?
        super
      else
        Array(sorted_key_date).flat_map { |d| DateUtil.extract_year(d) }
      end
    end

    def sorted_key_date
      return unless key_date

      if timespan?
        super
      else
        key_date.sort { |a, b| DateUtil.extract_year(a) <=> DateUtil.extract_year(b) }
      end
    end

    def timespan?
      Array(key_date).first.is_a?(TimeSpan)
    end
end
