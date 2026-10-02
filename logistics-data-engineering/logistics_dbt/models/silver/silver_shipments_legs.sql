{% set legs = ["i1", "i2", "i3", "o"] %}

with
    unpivoted as (

        {% for leg in legs %}
            select
                nr,
                '{{ leg }}' as leg_type,
                {{ "true" if leg == "o" else "false" }} as is_outbound_leg,
                {{ clean_missing_numeric(leg ~ "_legid") }} as leg_id,
                {{ clean_missing_numeric(leg ~ "_rcs_p") }} as rcs_planned,
                {{ clean_missing_numeric(leg ~ "_rcs_e") }} as rcs_effective,
                {{ clean_missing_numeric(leg ~ "_dlv_p") }} as dlv_planned,
                {{ clean_missing_numeric(leg ~ "_dlv_e") }} as dlv_effective,
                {{ clean_missing_numeric(leg ~ "_hops") }} as hop_count
            from {{ ref("bronze_cargo_tracking") }}
            {% if not loop.last %}
                union all
            {% endif %}
        {% endfor %}

    ),

    cleaned as (

        select
            {{ generate_leg_key(["nr", "leg_type"]) }} as leg_key,
            nr as shipment_id,
            leg_type,
            is_outbound_leg,
            leg_id,
            rcs_planned,
            rcs_effective,
            {{ calculate_delay_minutes("rcs_planned", "rcs_effective") }}
            as rcs_delay_minutes,
            dlv_planned,
            dlv_effective,
            {{ calculate_delay_minutes("dlv_planned", "dlv_effective") }}
            as dlv_delay_minutes,
            hop_count
        from unpivoted
        -- a leg the shipment didn't use has NULL leg_id after cleaning
        where leg_id is not null

    )

select *
from cleaned
