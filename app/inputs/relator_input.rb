class RelatorInput < ControlledVocabularySelectInput
  protected

    def build_field(value, index)
      options = input_html_options.dup
      value = value.resource if value.is_a? ActiveFedora::Base

      if value.respond_to? :rdf_label
        options[:name] = name_for(attribute_name, index, 'hidden_label'.freeze)
        options[:data] = { attribute: attribute_name }
        options[:id] = id_for_hidden_label(index)
        if value.node?
          build_options_for_new_row(attribute_name, index, options)
        else
          build_options_for_existing_row(attribute_name, index, value, options)
        end
      end
      options[:required] = nil if @rendered_first_element
      options[:class] ||= []
      options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      options[:'aria-labelledby'] = label_id
      @rendered_first_element = true
      text_field = @builder.text_field(attribute_name, options)
      controls = content_tag(:div, text_field + hidden_id_field(value, index) +
                             hidden_predicate_field(value, index) + destroy_widget(attribute_name, index), class: 'input-group input-group-append')

      content_tag(:div, content_tag(:span, value.predicate.to_s.humanize, class: 'predicate'), class: 'role') +
        content_tag(:div, controls, class: 'text')
    end

    def inner_wrapper
      <<-HTML
          <li class="field-wrapper row existing">
            #{yield}
          </li>
        HTML
    end

    def hidden_predicate_field(value, index)
      name = name_for(attribute_name, index, 'predicate'.freeze)
      id = id_for(attribute_name, index, 'predicate'.freeze)
      hidden_value = value.node? ? '' : value.predicate
      @builder.hidden_field(attribute_name, name: name, id: id, value: hidden_value)
    end
end
