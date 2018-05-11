# frozen_string_literal: true

unless Rails.env.production?
  APP_ROOT = File.dirname(__FILE__)
  require "solr_wrapper"
  require "fcrepo_wrapper"

  desc "Run Continuous Integration"
  task :ci do
    ENV["environment"] = "test"
    solr_params = {
      instance_dir: Rails.root.join("tmp", "solr-test"),
      managed: true,
      mirror_url: "http://lib-solr-mirror.princeton.edu/dist/",
      port: 8985,
      solr_xml: Rails.root.join("solr", "config", "solrconfig.xml"),
      verbose: true,
      version: "6.3.0",
    }
    fcrepo_params = {
      fcrepo_home_dir: Rails.root.join("tmp", "fedora", "test"),
      managed: true,
      no_jms: true,
      port: 8986,
      verbose: true,
      version: "4.6.0",
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
