# frozen_string_literal: true

class CatalogController < ApplicationController
  include BlacklightRangeLimit::ControllerOverride
  include CurationConcerns::CatalogController
  include Hydra::Controller::ControllerBehavior
  include BlacklightOaiProvider::Controller

  # enforce_show_permissions is from hydra-access-controls gem
  before_action :enforce_show_permissions, only: :show

  def enforce_show_permissions(_opts = {})
    permissions = current_ability.permissions_doc(params[:id])
    return if can?(:discover, permissions)

    raise Hydra::AccessDenied.new(
      "You do not have sufficient access privileges to access this document.",
      :discover, params[:id]
    )
  end

  rescue_from Blacklight::Exceptions::RecordNotFound do |e|
    logger.error "(Blacklight::Exceptions::RecordNotFound): #{e.inspect}"
    @unknown_type = "Document"
    @unknown_id = params[:id]
    render "errors/not_found", status: 404
  end

  rescue_from Blacklight::Exceptions::InvalidSolrID do |e|
    logger.error e
    @unknown_type = "Document"
    @unknown_id = params[:id]
    render "errors/not_found", status: 404
  end

  # Turn off SMS
  # https://groups.google.com/d/msg/blacklight-development/l_zHRF_GQc8/_qUUbJSs__YJ
  CatalogController.blacklight_config.show.document_actions.delete(:sms)

  # TODO: re-implement this functionality
  # https://github.library.ucsb.edu/ADRL/alexandria/pull/29
  # https://help.library.ucsb.edu/browse/DIGREPO-504
  CatalogController.blacklight_config.show.document_actions.delete(:email)
  CatalogController.blacklight_config.show.document_actions.delete(:citation)

  add_show_tools_partial(:edit, partial: "catalog/edit", if: :editor?)
  add_show_tools_partial(:download, partial: "catalog/download")
  add_show_tools_partial(:access,
                         partial: "catalog/access",
                         if: :show_embargos_link?)

  configure_blacklight do |config|
    config.search_builder_class = SearchBuilder
    config.view.gallery.partials = [:index_header, :index]
    config.view.slideshow.partials = [:index]
    config.view.slideshow.slideshow_method = :choose_image

    config.oai = {
      provider: {
        repository_name: Settings.oai_repository_name,
        repository_url: Settings.oai_repository_url,
        record_prefix: Settings.oai_record_prefix,
        admin_email: Rails.application.secrets.oai_admin_email,
      },
      document: {
        limit: 25,
      }
    }

    # This controls which partials are used, and in what order, for
    # each record type.  E.g., for an AudioRecording we will render
    #
    # - _breadcrumbs_audio_recording.html.erb
    # - _title_audio_recording.html.erb
    # - _media_audio_recording.html.erb
    # - _show_audio_recording.html.erb
    # - _downloads_audio_recording.html.erb
    #
    # falling back to _title_default etc. in each case.
    config.show.partials = [
      :breadcrumbs,
      :title,
      :media,
      :show,
      :downloads,
    ]

    # config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    # config.show.partials.insert(1, :openseadragon)

    config.default_solr_params = {
      qf: %w[
        accession_number_tesim
        alternative_tesim
        author_tesim
        keywords_tesim
        lc_subject_label_tesim
        location_label_tesim
        title_tesim
        all_text_timv
      ].join(" "),
      wt: "json",
      qt: "search",
      rows: 10,
    }

    # solr field configuration for search results/index views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = "has_model_ssim"
    config.index.thumbnail_field = ObjectIndexer.thumbnail_field

    # Solr fields that will be treated as facets by the blacklight application
    #
    # The ordering of the field names is the order of the display.
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    #
    # * If left unset, then all facet values returned by solr will be
    #   displayed (not always all results in Fedora; see
    #   https://github.library.ucsb.edu/ADRL/alexandria/issues/13)
    #
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    #   solr request, with actual solr request being +1 your configured limit --
    #   you configure the number of items you actually want _tsimed_ in a page.
    #
    # * If set to 'true', then no additional parameters will be sent
    #   to solr, but any 'sniffed' request limit parameters will be
    #   used for paging, with paging at requested limit -1. Can sniff
    #   from facet.limit or f.specific_field.facet.limit solr request
    #   params. This 'true' config can be used if you set limits in
    #   :default_solr_params, or as defaults on the solr side in the
    #   request handler itself. Request handler defaults sniffing
    #   requires solr requests to be made with "echoParams=all", for
    #   app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    config.add_facet_field solr_name("work_type_label", :facetable),
                           label: "Format", limit: true

    config.add_facet_field solr_name("collection_label", :symbol),
                           label: "Collection", limit: true

    config.add_facet_field ObjectIndexer::ALL_CONTRIBUTORS_FACET,
                           label: "Contributor", limit: true

    config.add_facet_field solr_name("lc_subject_label", :facetable),
                           label: "Topic", limit: 20

    config.add_facet_field solr_name("location_label", :facetable),
                           label: "Place", limit: true

    config.add_facet_field solr_name("form_of_work_label", :facetable),
                           label: "Genre", limit: true

    config.add_facet_field ObjectIndexer::FACETABLE_YEAR,
                           label: "Date", range: true

    config.add_facet_field solr_name("language", :facetable),
                           label: "Language", limit: true

    config.add_facet_field solr_name("department", :facetable),
                           label: "Academic Department", limit: true

    config.add_facet_field solr_name("sub_location", :facetable),
                           label: "Library Location", limit: true

    config.add_facet_field solr_name("license_label", :facetable),
                           label: "Rights", limit: true

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!
    # use this instead if you don't want to query facets marked :show=>false
    # config.default_solr_params[:'facet.field'] =
    #   config.facet_fields.select { |_k, v| v[:show] != false }.keys

    # Solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("work_type_label", :stored_searchable),
                           label: "Format"

    config.add_index_field solr_name("collection_label", :symbol),
                           label: "Collection"

    config.add_index_field ObjectIndexer::ALL_CONTRIBUTORS_LABEL,
                           label: "Contributors",
                           if: :show_contributors?

    config.add_index_field solr_name("author", :stored_searchable),
                           label: "Author", if: :show_author?

    config.add_index_field solr_name("created", :displayable),
                           label: "Creation Date"

    config.add_index_field solr_name("issued", :displayable),
                           label: "Issued Date"

    config.add_index_field solr_name("description", :stored_searchable),
                           label: "Summary",
                           if: :collection?

    # Solr fields to be displayed in the show (item-level) view
    #   The ordering of the field names is the order of the display
    Metadata::RELATIONS.keys.each do |key|
      config.add_show_field solr_name("#{key}_label", :stored_searchable),
                            label: key.to_s.titleize,
                            link_to_search: "all_contributors_label_sim"
    end

    config.add_show_field solr_name("alternative", :stored_searchable),
                          label: "Variant Title"

    config.add_show_field solr_name("place_of_publication", :stored_searchable),
                          label: "Place of Publication"

    config.add_show_field solr_name("publisher", :stored_searchable),
                          label: "Publisher"

    config.add_show_field solr_name("created", :displayable),
                          label: "Creation Date"

    config.add_show_field solr_name("issued", :displayable),
                          label: "Issued Date"

    config.add_show_field solr_name("date_other", :displayable),
                          label: "Other Date"

    config.add_show_field solr_name("language", :stored_searchable),
                          label: "Language"

    config.add_show_field solr_name("lc_subject_label", :stored_searchable),
                          label: "Topics",
                          link_to_search: "lc_subject_label_sim"

    config.add_show_field solr_name("marc_subjects", :stored_searchable),
                          label: "Topics",
                          link_to_search: "marc_subjects_sim"

    config.add_show_field solr_name("location_label", :stored_searchable),
                          label: "Places",
                          link_to_search: "location_label_sim"

    config.add_show_field(
      solr_name("keywords", :stored_searchable),
      label: "Keywords",
      separator_options: {
        words_connector: '<span class="invisible">,</span> <br />',
        two_words_connector: '<span class="invisible">,</span> <br />',
        last_word_connector: '<span class="invisible">, and</span> <br />',
      }
    )

    config.add_show_field solr_name("form_of_work_label", :stored_searchable),
                          label: "Genres",
                          link_to_search: "form_of_work_label_sim"

    config.add_show_field solr_name("degree_grantor", :symbol),
                          label: "Degree Grantor"

    config.add_show_field solr_name("dissertation", :displayable),
                          label: "Dissertation"

    config.add_show_field solr_name("note_label", :stored_searchable),
                          label: "Notes",
                          helper_method: "not_simple_format"

    config.add_show_field solr_name("citation", :displayable), label: "Citation"

    config.add_show_field solr_name("description", :stored_searchable),
                          label: "Summary",
                          helper_method: "not_simple_format"

    config.add_show_field solr_name("extent", :displayable),
                          label: "Physical Description"

    config.add_show_field solr_name("scale", :stored_searchable), label: "Scale"

    config.add_show_field solr_name("work_type_label", :stored_searchable),
                          label: "Format",
                          link_to_search: "work_type_label_sim"

    config.add_show_field solr_name("collection_label", :symbol),
                          label: "Collection(s)",
                          link_to_search: "collection_label_ssim"

    config.add_show_field solr_name("series_name", :displayable),
                          label: "Series",
                          link_to_search: "series_name_sim"

    config.add_show_field solr_name("folder_name", :stored_searchable),
                          label: "Folder",
                          link_to_search: "folder_name_sim"

    config.add_show_field solr_name("finding_aid", :stored_searchable),
                          label: "Finding Aid"

    config.add_show_field(
      solr_name("sub_location", :displayable, type: :string),
      label: "Library Location",
      link_to_search: "sub_location_sim"
    )

    config.add_show_field solr_name("fulltext_link", :displayable),
                          label: "Other Versions",
                          helper_method: :display_link

    config.add_show_field solr_name("identifier", :displayable),
                          label: "ARK"

    config.add_show_field solr_name("accession_number", :symbol),
                          label: "Local Identifier"

    config.add_show_field "isbn_ssim", label: "ISBN"

    config.add_show_field solr_name("matrix_number", :stored_searchable),
                          label: "Matrix Number"

    config.add_show_field solr_name("issue_number", :stored_searchable),
                          label: "Issue Number"

    config.add_show_field solr_name("system_number", :symbol),
                          label: "Catalog System Number"

    config.add_show_field solr_name("copyright", :displayable),
                          label: "Copyright"

    config.add_show_field solr_name("license_label", :stored_searchable),
                          label: "Rights",
                          helper_method: "show_license_icons"

    config.add_show_field solr_name("rights_holder_label", :stored_searchable),
                          label: "Copyright Holder"

    config.add_show_field solr_name("date_copyrighted", :displayable),
                          label: "Copyright Date"

    config.add_show_field solr_name("restrictions", :stored_searchable),
                          label: "Restrictions",
                          helper_method: "not_simple_format"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request
    # handler. Which solr request handler? The one set in
    # config[:default_solr_parameters][:qt], since we aren't
    # specifying it otherwise.
    config.add_search_field "all_fields", label: "All Fields"

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    config.add_search_field("title") do |field|
      field.solr_local_parameters = {
        qf: "title_tesim",
        pf: "title_tesim",
      }
    end

    config.add_search_field("subject") do |field|
      field.solr_local_parameters = {
        qf: "lc_subject_label_tesim",
        pf: "lc_subject_label_tesim",
      }
    end

    config.add_search_field("accession_number") do |field|
      field.solr_local_parameters = {
        qf: "accession_number_tesim",
        pf: "accession_number_tesim",
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field(
      "score desc, #{ObjectIndexer::SORTABLE_DATE} desc, creator_label_si asc",
      label: "relevance"
    )
    config.add_sort_field(
      "#{ObjectIndexer::SORTABLE_DATE} asc, creator_label_si asc",
      label: "year ascending"
    )
    config.add_sort_field(
      "#{ObjectIndexer::SORTABLE_DATE} desc, creator_label_si asc",
      label: "year descending"
    )
    config.add_sort_field(
      "creator_label_si asc, #{ObjectIndexer::SORTABLE_DATE} asc",
      label: "creator ascending"
    )
    config.add_sort_field(
      "creator_label_si desc, #{ObjectIndexer::SORTABLE_DATE} asc",
      label: "creator descending"
    )

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def show_embargos_link?(_config, options)
    return false unless (doc = options.fetch(:document))
    doc.curation_concern? && can?(:update_rights, doc)
  end

  # Should we show the "edit metadata" link on the show page?
  # Only shows up for non-etd things
  def editor?(_user, stuff)
    document = stuff.fetch(:document)
    can?(:edit, document) && !document.etd?
  end

  # Overriding to permit parameters; see https://groups.google.com/d/msg/blacklight-development/Gr12dc1S4no/TQq3DQXABQAJ
  def search_state
    @search_state ||= search_state_class.new(
      params.permit!, blacklight_config, self
    )
  end
end
