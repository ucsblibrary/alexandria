module ApplicationHelper

  def on_campus_network_prefixes
    ['128.111', '169.231']
  end

  def on_campus?
    return false unless request.remote_ip
    on_campus_network_prefixes.any? {|prefix| request.remote_ip.start_with?(prefix) }
  end

  # Should we show the "edit metadata" link on the show page?
  # Only shows up for non-etd things
  def editor?(_, stuff)
    document = stuff.fetch(:document)
    can?(:edit, document) && !document.etd?
  end

  def link_to_collection(stuff)
    collection_id = Array(stuff.fetch(:document)[ImageIndexer::COLLECTION]).first
    if collection_id
      link_to stuff.fetch(:value).first, collections.collection_path(collection_id)
    else
      stuff.fetch(:value).first
    end
  end

  def display_notes(data)
    safe_join(Array(data[:value]), '<br/>'.html_safe)
  end

  # Should we display the admin menu?
  def admin_menu?
    can?(:discover, Hydra::AccessControls::Embargo) || can?(:destroy, :local_authorities)
  end

  def show_delete_link?(config, options)
    LocalAuthority.local_authority?(options.fetch(:document)) &&
      can?(:destroy, :local_authorities)
  end

  def show_merge_link?(config, options)
    LocalAuthority.local_authority?(options.fetch(:document)) &&
      can?(:merge, options.fetch(:document))
  end

end
