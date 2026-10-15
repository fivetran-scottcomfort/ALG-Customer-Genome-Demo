-- THE CUSTOMER GENOME: one golden-record row per person (or per anonymous device).
-- Survivorship rules come from seeds/survivorship_rules.csv: edit the seed, rerun, and the winning values change.
with profile_fields as (
  select
    genome_id,
    max(if(field_name = 'email'      and survivor_rank = 1, field_value,   null)) as primary_email,
    max(if(field_name = 'email'      and survivor_rank = 1, source_system, null)) as primary_email_source,
    max(if(field_name = 'phone'      and survivor_rank = 1, field_value,   null)) as primary_phone,
    max(if(field_name = 'phone'      and survivor_rank = 1, source_system, null)) as primary_phone_source,
    max(if(field_name = 'first_name' and survivor_rank = 1, field_value,   null)) as first_name,
    max(if(field_name = 'first_name' and survivor_rank = 1, source_system, null)) as first_name_source,
    max(if(field_name = 'last_name'  and survivor_rank = 1, field_value,   null)) as last_name,
    max(if(field_name = 'last_name'  and survivor_rank = 1, source_system, null)) as last_name_source,
    array_agg(distinct if(field_name = 'email', field_value, null) ignore nulls) as emails,
    array_agg(distinct if(field_name = 'phone', field_value, null) ignore nulls) as phones
  from {{ ref('int_field_candidates') }}
  group by genome_id
),

record_stats as (
  select
    rg.genome_id,
    min(r.event_ts) as first_seen_ts,
    max(r.event_ts) as last_seen_ts,
    min(if(r.user_id is not null, r.event_ts, null)) as identified_ts,
    count(distinct r.session_id) as visit_sessions,
    countif(r.source_system = 'web_booking') as booking_count,
    max(if(r.source_system = 'web_booking', r.event_ts, null)) as last_booking_ts,
    array_agg(distinct r.source_system) as source_systems
  from {{ ref('int_source_records') }} r
  join {{ ref('int_record_genome') }} rg on rg.source_record_id = r.source_record_id
  group by rg.genome_id
)

select
  rs.genome_id,
  case
    when pf.primary_email is not null and rs.visit_sessions >= 2 then 'known_returning'
    when pf.primary_email is not null then 'identified'
    when rs.visit_sessions >= 2 then 'anonymous_returning'
    else 'anonymous_new'
  end as genome_stage,
  pf.first_name,
  pf.last_name,
  pf.primary_email,
  {{ email_hash('pf.primary_email') }} as email_sha256,
  pf.primary_phone,
  pf.emails,
  pf.phones,
  gc.anonymous_ids,
  gc.reservation_ids,
  rs.visit_sessions,
  rs.booking_count,
  rs.last_booking_ts,
  rs.first_seen_ts,
  rs.last_seen_ts,
  rs.identified_ts,
  rs.source_systems,
  pf.primary_email_source,
  pf.primary_phone_source,
  pf.first_name_source,
  pf.last_name_source,
  gc.node_count,
  coalesce(gc.has_shared_identifier, false) as has_shared_identifier,
  coalesce(gc.is_quarantined, false) as is_quarantined
from record_stats rs
left join profile_fields pf on pf.genome_id = rs.genome_id
left join {{ ref('int_genome_components') }} gc on gc.genome_id = rs.genome_id
