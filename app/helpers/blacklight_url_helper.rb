module BlacklightUrlHelper
  include Blacklight::UrlHelperBehavior

  def url_for_document doc, options = {}
    return unless doc
    case Array(doc['has_model_ssim']).first
    when 'Collection'
      collections.collection_path(doc)
    when 'Image', 'ETD'
      ark_path(doc.ark.html_safe)
    else
      super
    end
  end

  # This is required because Blacklight 5.14 uses polymorphic_url
  # in render_link_rel_alternates
  def etd_url(*args)
    catalog_url(args)
  end

  # This is required because Blacklight 5.14 uses polymorphic_url
  # in render_link_rel_alternates
  def image_url(*args)
    catalog_url(args)
  end

  # we're using our own helper rather than the generated route helper because the
  # default helper escapes slashes. https://github.com/rails/rails/issues/16058
  def ark_path(ark)
    "/lib/#{ark}"
  end

  ##
  # Get the URL for tracking search sessions across pages using polymorphic routing
  def session_tracking_path document, params = {}
    track_solr_document_path(document, params)
  end
end
