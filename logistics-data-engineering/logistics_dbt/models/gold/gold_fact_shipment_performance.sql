with
    legs as (select * from {{ ref("gold_fact_leg_performance") }}),

    shipment_agg as (

        select
            shipment_id,
            count(*) as legs_used,
            max(dlv_delay_minutes) as worst_leg_delay_minutes,
            avg(dlv_delay_minutes) as avg_leg_delay_minutes
        from legs
        group by 1

    ),

    final_outbound_leg as (

        select
            shipment_id,
            dlv_planned as final_delivery_planned,
            dlv_effective as final_delivery_effective,
            dlv_delay_minutes as final_delivery_delay_minutes,
            dlv_sla_status as final_delivery_sla_status
        from legs
        where is_outbound_leg

    )

select
    a.shipment_id,
    a.legs_used,
    a.worst_leg_delay_minutes,
    a.avg_leg_delay_minutes,
    f.final_delivery_planned,
    f.final_delivery_effective,
    f.final_delivery_delay_minutes,
    f.final_delivery_sla_status
from shipment_agg a
left join final_outbound_leg f on a.shipment_id = f.shipment_id
