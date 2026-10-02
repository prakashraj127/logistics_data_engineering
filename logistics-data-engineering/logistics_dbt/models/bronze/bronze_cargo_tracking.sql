{{
    config(
        materialized="view",
    )
}}

select *
from {{ source("raw", "RAW_CARGO_TRACKING") }}
