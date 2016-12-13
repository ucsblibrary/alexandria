module NavMenuHelper

  def local_authorities_link
    return unless can_read_authorities?
    content_tag(:li) do
      link_to 'Local Authorities', main_app.local_authorities_path
    end
  end

  def new_record_link
    return unless can?(:create, ActiveFedora::Base)
    content_tag(:li) do
      link_to 'Add Record', hydra_editor.new_record_path
    end
  end

  def embargoes_link
    return unless embargo_manager?
    content_tag(:li) do
      link_to 'Embargoes', main_app.embargoes_path
    end
  end

end
