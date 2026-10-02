{% macro clean_missing_text(column_name) -%}
    nullif(trim(cast({{ column_name }} as {{ dbt.type_string() }})), '?')
{%- endmacro %}
