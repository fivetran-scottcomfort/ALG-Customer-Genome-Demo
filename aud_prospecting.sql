-- Use Case 2: PROSPECTING AUDIENCE. Point Activations at this table.
-- Visited more than one page in a session in the last 60 days, minus employees, competitors,
-- travel agents, shared devices, and anyone who booked in the last 30 days.
-- It is a full snapshot every run (not incremental), so paid media always receives the complete audience.
with qualifying_sessions as (
  select
    rg.genome_id,
    r.session_id,
    max(r.event_ts) as session_last_ts
  from {{ ref('int_source_records') }} r
  join {{ ref('int_record_genome') }} rg on rg.source_record_id = r.source_record_id
  where r.source_system = 'metarouter_page'
    and date(r.event_ts) > date_sub({{ as_of_date() }}, interval {{ var('prospect_lookback_days') }} day)
  group by rg.genome_id, r.session_id
  having count(*) > 1
),
eligible as (
  select genome_id, count(*) as multi_page_sessions, max(session_last_ts) as last_visit_ts
  from qualifying_sessions
  group by genome_id
)
select
  g.genome_id,
  g.genome_stage,
  g.primary_email,
  g.email_sha256,
  g.primary_phone,
  g.anonymous_ids[safe_offset(0)] as primary_anonymous_id,
  g.primary_email is not null or g.primary_phone is not null as is_matchable,
  e.multi_page_sessions,
  e.last_visit_ts
from eligible e
join {{ ref('customer_genome') }} g on g.genome_id = e.genome_id
where e.genome_id not in (select genome_id from {{ ref('aud_prospecting_suppression_log') }})
