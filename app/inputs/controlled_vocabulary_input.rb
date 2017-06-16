# frozen_string_literal: true

class ControlledVocabularyInput < MultiValueInput
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
      text_field = if options.delete(:type) == "textarea"
                     @builder.text_area(attribute_name, options)
                   else
                     @builder.text_field(attribute_name, options)
                   end

      text_field +
        hidden_id_field(value, index) +
        destroy_widget(attribute_name, index)
    end

    def id_for_hidden_label(index)
      id_for(attribute_name, index, "hidden_label")
    end

    def destroy_widget(attribute_name, index)
      @builder.hidden_field(attribute_name,
                            name: name_for(attribute_name, index, "_destroy"),
                            id: id_for(attribute_name, index, "_destroy"),
                            value: "", data: { destroy: true })
    end

    def hidden_id_field(value, index)
      name = name_for(attribute_name, index, "id")
      id = id_for(attribute_name, index, "id")

      # order matters here
      form_value = if (value.respond_to?(:empty?) && value.empty?) ||
                      (value.respond_to?(:node?) && value.node?)
                     ""
                   elsif value.respond_to? :rdf_subject
                     value.rdf_subject
                   else
                     value
                   end

      @builder.hidden_field(
        attribute_name,
        name: name,
        id: id,
        value: form_value,
        data: { id: "remote" }
      )
    end

    def build_options_for_new_row(_attribute_name, _index, options)
      options[:value] = ""
    end

    def build_options_for_existing_row(_attribute_name, _index, value, options)
      options[:value] = value || "Unable to fetch label for #{value}"
      options[:readonly] = true
    end

    def name_for(attribute_name, index, field)
      "#{@builder.object_name}[#{attribute_name}_attributes]"\
      "[#{index}][#{field}]"
    end

    def id_for(attribute_name, index, field)
      [
        @builder.object_name,
        "#{attribute_name}_attributes",
        index,
        field,
      ].join("_")
    end

    def collection
      @collection ||= Array.wrap(object[attribute_name]).reject do |value|
        value.to_s.strip.blank?
      end
    end
end
