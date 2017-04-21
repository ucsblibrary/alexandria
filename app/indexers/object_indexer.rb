# frozen_string_literal: true

class ObjectIndexer < CurationConcerns::WorkIndexer
  def rdf_service
    RDF::DeepIndexingService
  end

  self.thumbnail_field = "thumbnail_url_ssm"

  ISSUED = Solrizer.solr_name("issued", :displayable)
  CREATED = Solrizer.solr_name("created", :displayable)
  COPYRIGHTED = Solrizer.solr_name("date_copyrighted", :displayable)
  VALID = Solrizer.solr_name("date_valid", :displayable)
  OTHER = Solrizer.solr_name("date_other", :displayable)

  SORTABLE_DATE = Solrizer.solr_name("date", :sortable)
  FACETABLE_YEAR = "year_iim"

  COLLECTION_LABEL = Solrizer.solr_name("collection_label", :symbol)
  COLLECTION = Solrizer.solr_name("collection", :symbol)

  def generate_solr_document
    super do |solr_doc|
      collection_ids, collection_titles = collections
      solr_doc[COLLECTION] = collection_ids
      solr_doc[COLLECTION_LABEL] = collection_titles

      solr_doc[CREATED] = created
      solr_doc[OTHER] = display_date("date_other")
      solr_doc[VALID] = display_date("date_valid")

      solr_doc[SORTABLE_DATE] = sortable_date
      solr_doc[FACETABLE_YEAR] = facetable_year

      index_contributors(solr_doc)
      solr_doc["note_label_tesim"] = object.notes.map(&:value).flatten
      solr_doc["rights_holder_label_tesim"] = object["rights_holder"].map(&:rdf_label).flatten

      yield(solr_doc) if block_given?
    end
  end

  private

    # Find all the collections the object belongs to, whether
    # it has normal hydra-style collection membership or it
    # uses the "local_collection_id" work-around to associate
    # the object with a collection.
    # Returns two arrays, a list of ids and a list of titles.
    def collections
      results = (query_for_local_collections + query_for_hydra_collections).uniq
      results.map { |coll| [coll["id"], coll["title_tesim"]] }.transpose.map(&:flatten)
    end

    def query_for_local_collections
      return [] if object.local_collection_id.blank?
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(object.local_collection_id)
      ActiveFedora::SolrService.query(query, fl: "title_tesim id")
    end

    def query_for_hydra_collections
      return [] unless object.id
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_rel(member_ids: object.id, has_model: Collection.to_class_uri)
      ActiveFedora::SolrService.query(query, fl: "title_tesim id")
    end

    def index_contributors(solr_doc)
      ContributorIndexer.new(object).generate_solr_document(solr_doc)
    end

    def display_date(date_name)
      Array(object[date_name]).map(&:display_label)
    end

    def created
      return if object.created.blank?
      object.created.first.display_label
    end

    # Create a date field for sorting on
    def sortable_date
      Array(sorted_key_date).first.try(:earliest_year)
    end

    # Create a year field (integer, multiple) for faceting on
    def facetable_year
      Array(sorted_key_date).flat_map { |d| d.try(:to_a) }
    end

    def key_date
      return @key_date if @key_date

      # Look through all the dates in order of importance, and
      # find the first one that has a value assigned.
      date_names = [:created, :issued, :date_copyrighted, :date_other, :date_valid]

      date_names.each do |date_name|
        if object[date_name].present?
          @key_date = object[date_name]
          break
        end
      end
      @key_date
    end

    def sorted_key_date
      return unless key_date
      key_date.sort_by(&:earliest_year)
    end

    def issued
      return if object.issued.blank?
      object.issued.first.display_label
    end

    #
    # For objects with image attachments
    #

    # Called by the CurationConcerns::WorkIndexer
    def square_thumbnail_images
      file_set_images("100,", "square")
    end

    def thumbnail_path
      file_set_images("300,")
    end

    def file_set_large_images
      file_set_images("1000,")
    end

    def file_set_images(size = "400,", region = "full")
      object.file_sets.map do |file_set|
        file = file_set.files.first
        next unless file
        Riiif::Engine.routes.url_helpers.image_url(
          file.id,
          size: size,
          region: region,
          only_path: true
        )
      end
    end

    def file_set_iiif_manifests
      object.file_sets.map do |file_set|
        file = file_set.files.first
        next unless file
        Riiif::Engine.routes.url_helpers.info_path(file.id)
      end
    end
end
