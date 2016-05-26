module ApplicationHelper
  include CurationConcerns::CatalogHelper

  def link_to_collection(stuff)
    collection_id = Array(stuff.fetch(:document)[ImageIndexer::COLLECTION]).first
    if collection_id
      link_to stuff.fetch(:value).first, collections.collection_path(collection_id)
    else
      stuff.fetch(:value).first
    end
  end

  def display_notes(data)
    Array(data[:value]).map do |note|
      "<p>#{note}</p>"
    end.join('').html_safe
  end

  def not_simple_format(data)
    data[:value].first.split('\n\n').map { |para| "<p>#{para}</p>" }.join('').html_safe
  end

  def display_link(data)
    href = data.fetch(:value).first
    link_to(href, href)
  end

  def policy_title(document)
    AdminPolicy.find(document.admin_policy_id)
  end
end
