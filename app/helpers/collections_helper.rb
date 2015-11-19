module CollectionsHelper
  def has_collection_search_parameters?
    !params[:cq].blank?
  end

  # If the description is too long, include a more/less toggle
  # to truncate and show/hide long descriptions.
  def render_description(solr_doc)
    return unless solr_doc['description_tesim']

    long_desc = Array(solr_doc['description_tesim']).first
    max_length = 400

    if long_desc && long_desc.length > max_length
      short_desc = long_desc.truncate(max_length - 30)

      show_less = content_tag(:span, ' show less', class: 'link-style more-less-toggle')
      show_more = content_tag(:span, ' show more', class: 'link-style more-less-toggle reveal-js')

      long_field = content_tag(:div, safe_join([long_desc, show_less], ' '), class: 'show-less')
      short_field = content_tag(:div, safe_join([short_desc, show_more], ' '), class: 'show-more')

      display_fields = content_tag(:div, safe_join([short_field, long_field], ' '))

    else
      long_field = content_tag(:div, long_desc)
      display_fields = long_field
    end

    display_fields
  end
end
