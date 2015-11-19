class MultiValueReadonlyInput < MultiValueInput
  def input(_wrapper_options)
    @rendered_first_element = false
    input_html_classes.unshift('string')
    input_html_options[:name] ||= "#{object_name}[#{attribute_name}][]"
    markup = <<-HTML


        <ul class="listing">
    HTML

    collection.each_with_index do |value, index|
      markup << <<-HTML
        <li>
          #{build_field(value, index)}
        </li>
      HTML
    end

    markup << <<-HTML
        </ul>

    HTML
  end

  def collection
    @collection ||= Array.wrap(object[attribute_name]).reject { |value| value.to_s.strip.blank? }
  end
end
