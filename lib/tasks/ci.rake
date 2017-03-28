# frozen_string_literal: true

unless Rails.env.production?
  APP_ROOT = File.dirname(__FILE__)
  require "solr_wrapper"
  require "fcrepo_wrapper"

  desc "Run Continuous Integration"
  task :ci do
    ENV["environment"] = "test"
    solr_params = {
      version: "6.2.0",
      port: 8985,
      verbose: true,
      managed: true,
      solr_xml: Rails.root.join("solr", "config", "solrconfig.xml"),
    }
    fcrepo_params = {
      version: "4.6.0",
      port: 8986,
      verbose: true,
      managed: true,
      no_jms: true,
      fcrepo_home_dir: "fcrepo4-test-data",
    }
    SolrWrapper.wrap(solr_params) do |solr|
      solr.with_collection(
        name: "test",
        persist: false,
        dir: Rails.root.join("solr", "config")
      ) do
        FcrepoWrapper.wrap(fcrepo_params) do
          Rake::Task["spec"].invoke
        end
      end
    end
    Rake::Task["doc"].invoke
  end
end
