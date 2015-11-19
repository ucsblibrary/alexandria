class MultiValueSelectInput < MultiValueInput
  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  def input_type
    'multi_value'.freeze
  end

  protected

    # Delegate this completely to the form.
    def collection
      @collection ||= object[attribute_name]
    end

  private

    def select_options
      @select_options ||= begin
        collection = options.delete(:collection) || self.class.boolean_collection
        collection.respond_to?(:call) ? collection.call : collection.to_a
      end
    end

    def build_field(value, _index)
      html_options = input_html_options.dup

      if @rendered_first_element
        html_options[:id] = nil
        html_options[:required] = nil
      else
        html_options[:id] ||= input_dom_id
      end
      html_options[:class] ||= []
      html_options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      html_options[:'aria-labelledby'] = label_id
      html_options.delete(:multiple)
      @rendered_first_element = true

      selected_option = value.respond_to?(:id) ? value.id : value
      html_options.merge!(prompt: '') if selected_option.blank?
      template.select_tag(attribute_name, template.options_for_select(select_options, selected_option), html_options)
    end
end
