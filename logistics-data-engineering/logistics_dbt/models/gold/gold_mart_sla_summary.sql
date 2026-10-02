select
    leg_type,
    count(*) as total_legs,
    sum(case when dlv_sla_status = 'ON_TIME' then 1 else 0 end) as on_time_legs,
    sum(case when dlv_sla_status = 'DELAYED' then 1 else 0 end) as delayed_legs,
    sum(case when dlv_sla_status = 'UNKNOWN' then 1 else 0 end) as unknown_legs,
    round(
        100.0
        * sum(case when dlv_sla_status = 'ON_TIME' then 1 else 0 end)
        / nullif(
            sum(case when dlv_sla_status in ('ON_TIME', 'DELAYED') then 1 else 0 end), 0
        ),
        2
    ) as on_time_pct,
    avg(dlv_delay_minutes) as avg_delay_minutes
from {{ ref("gold_fact_leg_performance") }}
group by 1
order by 1
