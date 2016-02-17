module CollectionsHelper
  # If the description is too long, include a more/less toggle
  # to truncate and show/hide long descriptions.
  def render_description(solr_doc)
    return unless solr_doc['description_tesim']
    content_tag(:div, Array(solr_doc['description_tesim']).first)
  end
end
