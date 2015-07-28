# -*- encoding : utf-8 -*-
class SolrDocument

  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument


  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
  use_extension(ExportAsTurtle)

  ##
  # Offer the source (ActiveFedora-based) model to Rails for some of the
  # Rails methods (e.g. link_to).
  # @example
  #   link_to '...', SolrDocument(id: 'bXXXXXX5').new => <a href="/dams_object/bXXXXXX5">...</a>
  def to_model
    if self['has_model_ssim'] == [Collection.to_class_uri]
      @m ||= ActiveFedora::Base.load_instance_from_solr(id)
      return self if @m.class == ActiveFedora::Base
      @m
    else
      super
    end
  end

  def etd?
    self['has_model_ssim'] == [ETD.to_class_uri]
  end

  def to_param
    Identifier.ark_to_noid(ark) || Identifier.noidify(id)
  end

  def ark
    Array(self[Solrizer.solr_name('identifier', :displayable)]).first
  end

  def generic_files
    @generic_files ||= begin
      ids = fetch('generic_file_ids_ssim')
      docs = ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}").map { |res| SolrDocument.new(res) }
      ids.map { |id| docs.find { |doc| doc.id == id } }
    end
  end
end
