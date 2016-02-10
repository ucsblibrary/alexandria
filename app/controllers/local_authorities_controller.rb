class LocalAuthoritiesController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior

  before_filter :auth, only: :index

  add_show_tools_partial(:edit, partial: 'catalog/edit', if: :editor?)
  add_show_tools_partial(:merge, partial: 'catalog/merge_link', if: :show_merge_link?)
  add_show_tools_partial(:delete, partial: 'catalog/delete', if: :show_delete_link?)

  configure_blacklight do |config|
    config.search_builder_class = LocalAuthoritiesSearchBuilder

    config.index.document_actions.delete(:bookmark)
    config.show.document_actions.delete(:email)
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:citation)
    config.add_results_document_tool(:edit, partial: 'edit_controls')

    config.add_results_collection_tool(:add_another)

    # Display the admin menu in the nav header if the user is an admin
    config.add_nav_action(:admin_menu, partial: 'shared/admin_menu', if: :admin_menu?, class: 'dropdown')

    # solr fields to be displayed in the show (single result) view
    # The ordering of the field names is the order of the display
    config.add_show_field 'foaf_name_tesim', label: 'Name'
    config.add_show_field 'public_uri_ssim', label: 'URI'
    config.add_show_field 'label_tesim', label: 'Label'
    config.add_show_field 'has_model_ssim', label: 'Type'


    config.default_solr_params = {
      qf: 'foaf_name_tesim label_tesim',
      wt: 'json',
      qt: 'search',
      rows: 10,
    }

    config.add_search_field('name') do |field|
      field.solr_local_parameters = {
        qf: 'foaf_name_tesim label_tesim',
        pf: 'foaf_name_tesim label_tesim',
      }
    end

    config.add_facet_field 'active_fedora_model_ssi', label: 'Type', sort: 'index', collapse: false
    config.add_index_field 'public_uri_ssim', label: 'URI'

    config.index.title_field = %w(foaf_name_tesim label_tesim)
    config.add_index_field 'active_fedora_model_ssi', label: 'Type'
  end # configure_blacklight

  # Override rails path for the views so that we can use
  # regular blacklight views from app/views/catalog
  def _prefixes
    @_prefixes ||= super + ['catalog']
  end

  private

    def auth
      authorize! :read, :local_authorities
    end

    # Should we show the "edit metadata" link on the show page?
    # Only shows up for non-etd things
    def editor?(_, stuff)
      document = stuff.fetch(:document)
      can?(:edit, document)
    end

    def show_delete_link?(_config, options)
      can?(:destroy, :local_authorities)
    end

    def show_merge_link?(_config, options)
      can?(:merge, options.fetch(:document))
    end
end
