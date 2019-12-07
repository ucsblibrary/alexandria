# frozen_string_literal: true

class RelatorInput < ControlledVocabularySelectInput
  protected

    def build_field(value, index)
      options = input_html_options.dup
      value = value.resource if value.is_a? ActiveFedora::Base
      value = value.first if value.is_a? ActiveTriples::Relation

      options[:name] = name_for(attribute_name, index, "hidden_label")
      options[:data] = { attribute: attribute_name }
      options[:id] = id_for_hidden_label(index)

      if value.nil? || value.node?
        build_options_for_new_row(attribute_name, index, options)
      else
        build_options_for_existing_row(
          attribute_name,
          index,
          (value.respond_to?(:rdf_label) ? value.rdf_label.first : value),
          options
        )
      end

      options[:required] = nil if @rendered_first_element
      options[:class] ||= []
      options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      options[:'aria-labelledby'] = label_id
      @rendered_first_element = true
      text_field = @builder.text_field(attribute_name, options)

      controls = content_tag(
        :div,
        (text_field +
         hidden_id_field(value, index) +
         hidden_predicate_field(value, index) +
         destroy_widget(attribute_name, index)),
        class: "input-group input-group-append"
      )

      content_tag(:div, controls, class: "text") +
        content_tag(
          :div,
          content_tag(:span,
                      value.predicate.to_s.humanize,
                      class: "predicate"),
          class: "role"
        )
    end

    def inner_wrapper
      <<-HTML
          <li class="field-wrapper row existing">
            #{yield}
          </li>
      HTML
    end

    def hidden_predicate_field(value, index)
      name = name_for(attribute_name, index, "predicate")
      id = id_for(attribute_name, index, "predicate")
      hidden_value = value.node? ? "" : value.predicate

      @builder.hidden_field(
        attribute_name,
        name: name,
        id: id,
        value: hidden_value
      )
    end
end
