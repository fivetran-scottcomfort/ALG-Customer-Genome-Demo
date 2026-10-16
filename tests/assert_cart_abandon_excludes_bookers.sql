-- Fails if anyone with a booking in the last 30 days is in the cart-abandon audience.
select a.genome_id
from {{ ref('aud_cart_abandon') }} a
join {{ ref('customer_genome') }} g on g.genome_id = a.genome_id
where g.last_booking_ts is not null
  and date(g.last_booking_ts) >= date_sub({{ as_of_date() }}, interval {{ var('recent_booker_days') }} day)
