-- Use Case 1: CART-ABANDON AUDIENCE. Point Activations at this table (Iterable, Attentive, Meta).
-- A profile is in the audience when its latest cart is recent, and it has NOT booked
-- after that cart, and has not booked anywhere in the last 30 days.
-- Trip details (origin, destination, dates, hotel, image) are included for personalization.
with carts as (
  select
    rg.genome_id,
    timestamp(c.event_ts) as cart_ts,
    c.origin,
    c.destination,
    date(c.depart_date) as depart_date,
    date(c.return_date) as return_date,
    c.hotel_name,
    c.hotel_image_url,
    c.cart_value
  from {{ ref('raw_metarouter_cart') }} c
  join {{ ref('int_record_genome') }} rg
    on rg.source_record_id = concat('cart:', cast(c.event_id as string))
),
latest_cart as (
  select * except (rn)
  from (
    select *, row_number() over (partition by genome_id order by cart_ts desc) as rn
    from carts
  )
  where rn = 1
)
select
  g.genome_id,
  g.genome_stage,
  g.first_name,
  g.primary_email,
  g.email_sha256,
  g.primary_phone,
  g.anonymous_ids[safe_offset(0)] as primary_anonymous_id,
  g.primary_email is not null or g.primary_phone is not null as is_matchable,
  c.cart_ts,
  c.origin,
  c.destination,
  c.depart_date,
  c.return_date,
  c.hotel_name,
  c.hotel_image_url,
  c.cart_value
from latest_cart c
join {{ ref('customer_genome') }} g on g.genome_id = c.genome_id
where date(c.cart_ts) > date_sub({{ as_of_date() }}, interval {{ var('cart_lookback_days') }} day)
  and not g.has_shared_identifier
  and (
    g.last_booking_ts is null
    or (g.last_booking_ts < c.cart_ts
        and date(g.last_booking_ts) < date_sub({{ as_of_date() }}, interval {{ var('recent_booker_days') }} day))
  )
