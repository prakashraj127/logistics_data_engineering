{% macro sla_status(delay_col, threshold_minutes=0) -%}
    case
        when {{ delay_col }} is null
        then 'UNKNOWN'
        when {{ delay_col }} <= {{ threshold_minutes }}
        then 'ON_TIME'
        else 'DELAYED'
    end
{%- endmacro %}
