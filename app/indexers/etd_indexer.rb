# frozen_string_literal: true

class ETDIndexer < ObjectIndexer
  def thumbnail_path
    ActionController::Base.helpers.image_path(
      "fontawesome/black/png/256/file-text.png"
    )
  end

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name("member_ids", :symbol)] = object.member_ids

      rights_holders = object.rights_holder.map do |holder|
        (holder.respond_to?(:rdf_label) ? holder.rdf_label.first : holder)
      end.join(" and ")

      if rights_holders.present?
        solr_doc[Solrizer.solr_name("copyright", :displayable)] =
          "#{rights_holders}, #{object.date_copyrighted.first}"
      end

      solr_doc[Solrizer.solr_name("department", :facetable)] =
        department(solr_doc)

      solr_doc[Solrizer.solr_name("dissertation", :displayable)] =
        dissertation
    end
  end

  private

    def dissertation
      return if [object.dissertation_degree,
                 object.dissertation_institution,
                 object.dissertation_year,].any? { |f| f.first.blank? }

      object.dissertation_degree.first +
        "--" +
        object.dissertation_institution.first +
        ", " +
        object.dissertation_year.first
    end

    # Derive department by stripping "UC, SB" from the degree grantor field
    def department(solr_doc)
      Array(solr_doc[Solrizer.solr_name("degree_grantor", :symbol)])
        .map { |a| a.sub(/^University of California, Santa Barbara\. /, "") }
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
        key_date.sort do |a, b|
          DateUtil.extract_year(a) <=> DateUtil.extract_year(b)
        end
      end
    end

    def timespan?
      Array(key_date).first.is_a?(TimeSpan)
    end
end
