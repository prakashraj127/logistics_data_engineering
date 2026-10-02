with
    places as (

        select dep_place as place_code
        from {{ ref("silver_leg_hops") }}
        where dep_place is not null

        union all

        select rcf_place as place_code
        from {{ ref("silver_leg_hops") }}
        where rcf_place is not null

    )

select place_code, count(*) as hop_touch_count
from places
group by 1
order by hop_touch_count desc
