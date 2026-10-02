{% snapshot snap_shipment_leg_status %}

    {{
        config(
            target_schema="snapshots",
            unique_key="leg_key",
            strategy="check",
            check_cols=["rcs_effective", "dlv_effective", "dlv_delay_minutes"],
        )
    }}

    select
        leg_key,
        shipment_id,
        leg_type,
        is_outbound_leg,
        rcs_planned,
        rcs_effective,
        rcs_delay_minutes,
        dlv_planned,
        dlv_effective,
        dlv_delay_minutes
    from {{ ref("silver_shipments_legs") }}

{% endsnapshot %}
