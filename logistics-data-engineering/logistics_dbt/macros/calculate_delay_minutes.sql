{% macro calculate_delay_minutes(planned_col, effective_col) -%}
    case
        when {{ planned_col }} is not null and {{ effective_col }} is not null
        then {{ effective_col }} - {{ planned_col }}
        else null
    end
{%- endmacro %}
