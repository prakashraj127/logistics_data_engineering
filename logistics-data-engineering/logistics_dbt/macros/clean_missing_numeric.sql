{% macro clean_missing_numeric(column_name, data_type="integer") -%}
    cast(
        nullif(
            trim(cast({{ column_name }} as {{ dbt.type_string() }})), '?'
        ) as {{ data_type }}
    )
{%- endmacro %}
