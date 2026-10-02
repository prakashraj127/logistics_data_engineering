{% set legs = ["i1", "i2", "i3", "o"] %}
{% set hops = [1, 2, 3] %}

with
    unpivoted as (

        {% for leg in legs %}
            {% for hop in hops %}
                select
                    nr,
                    '{{ leg }}' as leg_type,
                    {{ hop }} as hop_number,
                    {{ clean_missing_numeric(leg ~ "_dep_" ~ hop ~ "_p") }}
                    as dep_planned,
                    {{ clean_missing_numeric(leg ~ "_dep_" ~ hop ~ "_e") }}
                    as dep_effective,
                    {{ clean_missing_text(leg ~ "_dep_" ~ hop ~ "_place") }}
                    as dep_place,
                    {{ clean_missing_numeric(leg ~ "_rcf_" ~ hop ~ "_p") }}
                    as rcf_planned,
                    {{ clean_missing_numeric(leg ~ "_rcf_" ~ hop ~ "_e") }}
                    as rcf_effective,
                    {{ clean_missing_text(leg ~ "_rcf_" ~ hop ~ "_place") }}
                    as rcf_place
                from {{ ref("bronze_cargo_tracking") }}
                {% if not (loop.last and leg == legs[-1]) %}
                    union all
                {% endif %}
            {% endfor %}
        {% endfor %}

    ),

    cleaned as (

        select
            {{ generate_leg_key(["nr", "leg_type", "hop_number"]) }} as hop_key,
            nr as shipment_id,
            leg_type,
            hop_number,
            dep_planned,
            dep_effective,
            {{ calculate_delay_minutes("dep_planned", "dep_effective") }}
            as dep_delay_minutes,
            dep_place,
            rcf_planned,
            rcf_effective,
            {{ calculate_delay_minutes("rcf_planned", "rcf_effective") }}
            as rcf_delay_minutes,
            rcf_place
        from unpivoted
        where dep_planned is not null

    )

select *
from cleaned
