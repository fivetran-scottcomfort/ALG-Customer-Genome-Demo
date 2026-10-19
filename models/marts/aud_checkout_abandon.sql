-- Use Case 1 (page-path version): CHECKOUT ABANDONERS.
-- Rule from the RFP: page path contains "/checkout" in the last 30 days, no "/checkout/confirmation"
-- in that window, and no booking in the last 30 days. Built from page events, so it needs no cart data.
-- (aud_cart_abandon is the richer sibling: same idea, plus the trip details for personalization.)
with window_pages as (
  select rg.genome_id, r.page_path, r.event_ts
  from {{ ref('int_source_records') }} r
  join {{ ref('int_record_genome') }} rg on rg.source_record_id = r.source_record_id
  where r.source_system = 'metarouter_page'
    and date(r.event_ts) > date_sub({{ as_of_date() }}, interval {{ var('checkout_lookback_days') }} day)
),
checkout_visits as (
  select genome_id, max(event_ts) as last_checkout_ts, count(*) as checkout_page_views
  from window_pages
  where starts_with(page_path, '/checkout')
  group by genome_id
),
confirmed as (
  select distinct genome_id
  from window_pages
  where page_path = '/checkout/confirmation'
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
  c.last_checkout_ts,
  c.checkout_page_views
from checkout_visits c
join {{ ref('customer_genome') }} g on g.genome_id = c.genome_id
where c.genome_id not in (select genome_id from confirmed)
  and not coalesce(date(g.last_booking_ts) >= date_sub({{ as_of_date() }}, interval {{ var('recent_booker_days') }} day), false)
  and not g.has_shared_identifier
