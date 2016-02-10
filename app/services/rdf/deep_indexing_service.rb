class RDF::DeepIndexingService < ActiveFedora::RDF::IndexingService
  # We're overiding the default indexer in order to index the RDF labels
  # @param [Hash] solr_doc
  # @param [String] solr_field_key
  # @param [Hash] field_info
  # @param [ActiveTriples::Resource, String] val
  def append_to_solr_doc(solr_doc, solr_field_key, field_info, val)
    return super unless object.controlled_properties.include?(solr_field_key)
    case val
    when ActiveTriples::Resource
      append_label_and_uri(solr_doc, solr_field_key, field_info, val)
    when String
      append_label(solr_doc, solr_field_key, field_info, val)
    else
      fail ArgumentError, "Can't handle #{val.class}"
    end
  end

  def add_assertions(*)
    fetch_external
    super
  end

  def fetch_external
    object.controlled_properties.each do |property|
      object[property].each do |value|
        resource = value.respond_to?(:resource) ? value.resource : value
        next unless resource.is_a?(ActiveTriples::Resource)
        next if value.is_a?(ActiveFedora::Base)
        old_label = resource.rdf_label.first
        next unless old_label == resource.rdf_subject.to_s || old_label.nil?
        fetch_value(resource) if resource.is_a? ActiveTriples::Resource
        if old_label != resource.rdf_label.first && resource.rdf_label.first != resource.rdf_subject.to_s
          resource.persist! # Stores the fetched values into our marmotta triplestore
        end
      end
    end
  end

  def fetch_value(value)
    Rails.logger.info "Fetching #{value.rdf_subject} from the authorative source. (this is slow)"
    value.fetch(headers: { 'Accept'.freeze => default_accept_header })
  rescue IOError, SocketError => e
    # IOError could result from a 500 error on the remote server
    # SocketError results if there is no server to connect to
    Rails.logger.error "Unable to fetch #{value.rdf_subject} from the authorative source.\n#{e.message}"
  end

  # Stripping off the */* to work around https://github.com/rails/rails/issues/9940
  def default_accept_header
    RDF::Util::File::HttpAdapter.default_accept_header.sub(/, \*\/\*;q=0\.1\Z/, '')
  end

  # Appends the uri to the default solr field and puts the label (if found) in the label solr field
  # @param [Hash] solr_doc
  # @param [String] solr_field_key
  # @param [Hash] field_info
  # @param [Array] val an array of two elements, first is a string (the uri) and the second is a hash with one key: `:label`
  def append_label_and_uri(solr_doc, solr_field_key, field_info, val)
    # begin
    #   # TODO This should not be in this method because it's slow. We should run it in a background job.
    #   # See https://github.com/OregonDigital/oregondigital/blob/master/lib/oregon_digital/rdf/deep_fetch.rb
    #   val.fetch
    # rescue SocketError, IOError => e
    #   Rails.logger.error "Couldn't fetch RDF label for #{val.id}\n#{e.message}"
    # end
    val = val.solrize
    self.class.create_and_insert_terms(solr_field_key,
                                       val.first,
                                       field_info.behaviors, solr_doc)
    if val.last.is_a? Hash
      self.class.create_and_insert_terms("#{solr_field_key}_label",
                                         label(val),
                                         field_info.behaviors, solr_doc)
    end
  end

  # Use this method to append a string value from a controlled vocabulary field
  # to the solr document. It just puts a copy into the corresponding label field
  # @param [Hash] solr_doc
  # @param [String] solr_field_key
  # @param [Hash] field_info
  # @param [String] val
  def append_label(solr_doc, solr_field_key, field_info, val)
    self.class.create_and_insert_terms(solr_field_key,
                                       val,
                                       field_info.behaviors, solr_doc)
    self.class.create_and_insert_terms("#{solr_field_key}_label",
                                       val,
                                       field_info.behaviors, solr_doc)
  end

  # Return a label for the solrized term:
  # @example
  #   label(["http://id.loc.gov/authorities/subjects/sh85062487", {:label=>"Hotels$http://id.loc.gov/authorities/subjects/sh85062487"}])
  #   => 'Hotels'
  def label(val)
    val.last[:label].split('$').first
  end
end
