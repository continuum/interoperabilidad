module HomeHelper

  def json_pointer_path(base, *new_components)
    return base if new_components.empty?
    base = '' if base == '/' # Avoid doubling slashes
    encoded_components = new_components.map do |arg|
      arg.gsub('~', '~0').gsub('/', '~1') # As per RFC 6901
    end
    encoded_components.unshift(base).join('/')
  end

  def schema_markup(schema_version)
    spec = schema_version.spec_with_resolved_refs['definition']
    references = schema_version.spec_with_resolved_refs['references']
    content_tag(:div, class: "schema-panel-set detail") do
      content_tag(:h3, s(schema_version.schema.name)) +
      if spec["type"] == "object"
        schema_object_spec_markup(spec, '/', references)
      else
        schema_object_property_markup('', spec, false, '/', references)
      end
    end
  end

  def schema_object_spec_markup(schema_object, json_pointer, references)
    schema_object['properties'].map do |name, property_definition|
      required =
        schema_object.has_key?("required") &&
        schema_object["required"].include?(name)
      schema_object_property_markup(
        name, property_definition, required,
        json_pointer_path(json_pointer, 'properties', name), references
      )
    end.join("".html_safe)
  end

  def schema_object_property_markup(name, property_definition, required, json_pointer, references)
    if property_definition["type"] == "object"
      schema_object_complex_property_markup(
        name, property_definition, required, json_pointer, references
      )
    elsif property_definition["type"] == "array"
      schema_object_array_property_markup(
        name, property_definition, required, json_pointer, references
      )
    else
      schema_object_primitive_property_markup(
        name, property_definition, required, json_pointer, references
      )
    end
  end

  def schema_link_if_reference_present(json_pointer, references)
    if references[json_pointer] && references[json_pointer]['type'] == 'remote'
      uri = references[json_pointer]['uri']
      content_tag(:a, class: "btn btn-static link-schema", href: uri) do
        content_tag(:span, "schema")
      end
    else
      "".html_safe
    end
  end

  # IMPORTANT NOTE: We use the `s_` prefix to denote variables already sanitized
  # from html. Also note that the `s()` function is an alias for sanitize()
  # defined at the end of this helper.
  #
  # That way, if we spot any variable not prefixed by `s_` and not
  # wrappend in `s()` being concatenated into HTML markup, it most likely means
  # we are introducing a XSS vulnerability

  def dynamic_component_structure(s_name_markup, property_definition, required, json_pointer, references)
    s_type_and_format = s(property_definition['type']) || ''
    if property_definition.has_key?('format')
      s_type_and_format += "(#{s(property_definition['format'])})"
    end
    content_tag(:div, nil, class: "panel-group") do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title " + (required ? "required" : "")) do
            content_tag(:div, nil, class: "col-md-6") do
              s_name_markup +
              content_tag(:p, s_type_and_format, class: "data-type") +
              content_tag(:p, s(property_definition['description']) || '',
                class: "description")
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              schema_link_if_reference_present(json_pointer, references) +
              content_tag(:ul) do
                schema_object_specific_markup(property_definition)
                schema_object_common_markup(property_definition)
              end
            end
          end
        end +
        content_tag(:div, nil, class: "panel-collapse collapse") do
          yield if block_given?
        end
      end
    end
  end

  def schema_object_primitive_property_markup(name, primitive_property_definition, required, json_pointer, references)
    s_name_markup = content_tag(:span, s(name), class: "name")
    dynamic_component_structure(
      s_name_markup, primitive_property_definition, required,
      json_pointer, references
    )
  end

  def schema_object_complex_property_markup(name, property_definition, required, json_pointer, references)
    s_name_markup = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, s(name), class: "name")
    end
    dynamic_component_structure(
      s_name_markup, property_definition, required, json_pointer, references
    ) do
      content_tag(:div, nil, class: "panel-body") do
        schema_object_spec_markup(property_definition, json_pointer, references)
      end
    end
  end

  def schema_object_array_property_markup(name, property_definition, required)
    s_name_markup = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, s(name), class: "name")
    end
    dynamic_component_structure(
      s_name_markup, property_definition, required, json_pointer, references
    ) do
      content_tag(:div, nil, class: "panel-body") do
        schema_object_property_markup(
          "(elementos)", property_definition["items"], false,
          json_pointer_path(json_pointer, "items"), references
        )
      end
    end
  end

  def schema_object_specific_markup(property_definition)
    case s(property_definition['type'])
    when "string"
      string_primitive_markup(property_definition)
    when "integer"
      numeric_primitive_markup(property_definition)
    when "number"
      numeric_primitive_markup(property_definition)
    when "array"
      array_specific_markup(property_definition)
    when "object"
      object_specific_markup(property_definition)
    end
  end

  def schema_object_common_markup(property_definition)
    if property_definition['default'].present?
      concat(content_tag(:li, 'por defecto ' + s(property_definition['default'].to_s)))
    end
    if property_definition['enum'].present?
      elements = "enum: ".html_safe
      property_definition['enum'].each do |element|
         elements += s(element) + '<br>'.html_safe
      end
      concat(content_tag(:li, elements))
    end
  end

  def markup_humanizer(name = '', suffix = '', max, min)
    if max.present? && min.present?
      if max == min
        concat(content_tag(:li, "largo #{s(max.to_s)} #{name}" +
          (max!=1 ? "#{suffix}" : "")))
      else
        concat(content_tag(:li, "rango #{s(min.to_s)}-#{s(max.to_s)} #{name}" +
          (max!=1 ? "#{suffix}" : "")))
      end
    else
      concat(content_tag(:li, "máximo #{s(max.to_s)} #{name}" +
        (max!=1 ? "#{suffix}" : ""))) if max.present?
      concat(content_tag(:li, "mínimo #{s(min.to_s)} #{name}" +
        (min!=1 ? "#{suffix}" : ""))) if min.present?
    end
  end

  def object_specific_markup(property_definition)
    max = property_definition['maxProperties']
    min = property_definition['minProperties']
    markup_humanizer("propiedad", "es", max, min)
  end

  def array_specific_markup(property_definition)
    max = property_definition['maxItems']
    min = property_definition['minItems']
    if property_definition['uniqueItems'].present?
      concat(content_tag(:li, "elementos únicos"))
    end
    markup_humanizer("elemento", "s", max, min)
  end

  def numeric_primitive_markup(primitive)
    max = primitive['maximum']
    min = primitive['minimum']
    exclusiveMax = primitive['exclusiveMaximum']
    exclusiveMin = primitive['exclusiveMinimum']
    if primitive['multipleOf'].present?
      concat(content_tag(:li, "múltiplo de #{s(primitive['multipleOf'].to_s)}"))
    end
    if max.present? && min.present?
      concat(content_tag(:li, "#{s(min.to_s)} " + (exclusiveMin ? "<" : "≤") +
        " x " + (exclusiveMax ? "<" : "≤") + " #{s(max.to_s)}"))
    else
      concat(content_tag(:li, "x " + (exclusiveMin ? ">" : "≥") +
        " #{s(min.to_s)}")) if min.present?
      concat(content_tag(:li, "x " + (exclusiveMax ? "<" : "≤") +
        " #{s(max.to_s)}")) if max.present?
    end
  end

  def string_primitive_markup(primitive)
    max = primitive['maxLength']
    min = primitive['minLength']
    if primitive['pattern'].present?
      concat(content_tag(:li, class: "reg-exp") do
        content_tag(:span, "#{s(primitive['pattern'])}")
      end)
    end
    markup_humanizer(max, min)
  end

  def s(content)
    sanitize(content)
  end
end
