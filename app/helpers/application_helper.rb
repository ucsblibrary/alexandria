module ApplicationHelper
  def link_to_collection(stuff)
    collection_id = Array(stuff.fetch(:document)[ImageIndexer::COLLECTION]).first
    if collection_id
      link_to stuff.fetch(:value).first, collections.collection_path(Identifier.noidify(collection_id))
    else
      stuff.fetch(:value).first
    end
  end

  def display_notes(data)
    safe_join(Array(data[:value]), '<br/>'.html_safe)
  end

  def display_link(data)
    href = data.fetch(:value).first
    link_to(href, href)
  end

  def policy_title(document)
    AdminPolicy.find(document.admin_policy_id)
  end
end
