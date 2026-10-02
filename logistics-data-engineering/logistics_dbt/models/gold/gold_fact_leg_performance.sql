select
    leg_key,
    shipment_id,
    leg_type,
    is_outbound_leg,
    leg_id,
    rcs_planned,
    rcs_effective,
    rcs_delay_minutes,
    {{ sla_status("rcs_delay_minutes") }} as rcs_sla_status,
    dlv_planned,
    dlv_effective,
    dlv_delay_minutes,
    {{ sla_status("dlv_delay_minutes") }} as dlv_sla_status,
    hop_count
from {{ ref("silver_shipments_legs") }}
