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

  ALL_CONTRIBUTORS_FACET = Solrizer.solr_name("all_contributors_label",
                                              :facetable)

  ALL_CONTRIBUTORS_LABEL = Solrizer.solr_name("all_contributors_label",
                                              :stored_searchable)

  SORTABLE_CREATOR = Solrizer.solr_name("creator_label", :sortable)
  CREATOR_MULTIPLE = Solrizer.solr_name("creator_label", :stored_searchable)

  def generate_solr_document
    super do |solr_doc|
      # override CurationConcerns::WorkIndexer to preserve FileSet
      # order
      solr_doc[Solrizer.solr_name("member_ids", :symbol)] = object.ordered_member_ids

      collection_ids, collection_titles = collections
      solr_doc[COLLECTION] = collection_ids
      solr_doc[COLLECTION_LABEL] = collection_titles

      solr_doc[CREATED] = created
      solr_doc[OTHER] = display_date("date_other")
      solr_doc[VALID] = display_date("date_valid")

      solr_doc[SORTABLE_DATE] = sortable_date
      solr_doc[FACETABLE_YEAR] = facetable_year

      solr_doc[SORTABLE_CREATOR] = sortable_creator(solr_doc)
      solr_doc[ALL_CONTRIBUTORS_LABEL] = all_contributors_combined
      solr_doc[ALL_CONTRIBUTORS_FACET] = solr_doc[ALL_CONTRIBUTORS_LABEL]

      # Used by OAI feed for collections: DIGREPO-903
      solr_doc["accession_number_normalized_ssm"] =
        [object["accession_number"].first&.tr(" ", "")&.downcase]

      # Primarily for the Index and Component Map trays, but also used
      # for collections' representative image thumbnail
      solr_doc["square_thumbnail_url_ssm"] = square_thumbnail_images

      solr_doc["note_label_tesim"] = object.notes.map do |note|
        note.value.first
      end.flatten

      solr_doc["rights_holder_label_tesim"] = object["rights_holder"].map do |s|
        s.respond_to?(:rdf_label) ? s.rdf_label : s
      end.flatten

      solr_doc["uri_ssm"] =
        "#{Settings.oai_identifier_prefix}#{object.identifier.first}"

      # Full-Text Indexing
      ::FullTextToSolrJob.new(solr_doc).perform

      yield(solr_doc) if block_given?
    end
  end

  private

    # Create a creator field suitable for sorting on
    def sortable_creator(solr_doc)
      solr_doc.fetch(CREATOR_MULTIPLE).first if solr_doc.key? CREATOR_MULTIPLE
    end

    # Returns the rdf label if it's a URI, otherwise the value itself.
    #
    # @return [NilClass, Array] Union of all the MARC relators. If non
    #     exist, return nil
    def all_contributors_combined
      Metadata::RELATIONS.keys.map do |field|
        next if object[field].empty?
        object[field].map do |val|
          val.respond_to?(:rdf_label) ? val.rdf_label.first : val
        end
      end.flatten.compact
    end

    # Find all the collections the object belongs to, whether
    # it has normal hydra-style collection membership or it
    # uses the "local_collection_id" work-around to associate
    # the object with a collection.
    # Returns two arrays, a list of ids and a list of titles.
    def collections
      results = (query_for_local_collections + query_for_hydra_collections).uniq

      results.map do |coll|
        [coll["id"], coll["title_tesim"]]
      end.transpose.map(&:flatten)
    end

    def query_for_local_collections
      return [] if object.local_collection_id.blank?
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(
        object.local_collection_id
      )
      ActiveFedora::SolrService.query(query, fl: "title_tesim id")
    end

    def query_for_hydra_collections
      return [] unless object.id
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_rel(
        member_ids: object.id,
        has_model: Collection.to_rdf_representation
      )
      ActiveFedora::SolrService.query(query, fl: "title_tesim id")
    end

    def display_date(date_name)
      [object[date_name].first.try(:display_label)]
    end

    def created
      return if object.created.blank?
      object.created.map(&:display_label)
    end

    # Create a date field for sorting on
    def sortable_date
      Array(sorted_key_date).first.try(:earliest_year)
    end

    # Create a year field (integer, multiple) for faceting on
    def facetable_year
      Array(sorted_key_date).flat_map { |d| d.try(:as_array) }
    end

    def key_date
      return @key_date if @key_date

      # Look through all the dates in order of importance, and
      # find the first one that has a value assigned.
      date_names = [
        :created,
        :issued,
        :date_copyrighted,
        :date_other,
        :date_valid,
      ]

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
      file_set_images(
        size: Settings.thumbnails["square"]["size"],
        region: Settings.thumbnails["square"]["region"]
      )
    end

    def thumbnail_path
      if object.file_sets.any?(&:image?)
        square_thumbnail_images
      # for e.g., scanned newspapers
      else
        ActionController::Base.helpers.image_path(
          "fontawesome/black/png/256/file-text.png"
        )
      end
    end

    def file_set_large_images
      file_set_images(size: Settings.thumbnails["large"]["size"])
    end

    def file_set_images(size: Settings.thumbnails["basic"]["size"], region: "full")
      object.ordered_members.to_a.map do |fs|
        file = fs.files.first
        next if file.blank?

        if Rails.configuration.try(:external_iiif_url)
          rotation = "0"
          quality = "default"
          format = "jpg"
          # rubocop:disable Metrics/LineLength
          "#{Rails.configuration.external_iiif_url}#{CGI.escape(file.id)}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          # rubocop:enable Metrics/LineLength
        else
          Riiif::Engine.routes.url_helpers.image_url(
            file.id,
            size: size,
            region: region,
            only_path: true
          )
        end
      end
    end

    # Define Rails.configuration.external_iiif_url to index against an external
    # iiif service
    def file_set_iiif_manifests
      object.ordered_members.to_a.map do |fs|
        file = fs.files.first
        next if file.blank?

        if Rails.configuration.try(:external_iiif_url)
          "#{Rails.configuration.external_iiif_url}#{CGI.escape(file.id)}/info.json"
        else
          Riiif::Engine.routes.url_helpers.info_path(file.id)
        end
      end
    end
end
