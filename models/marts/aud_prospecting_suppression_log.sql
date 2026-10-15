-- Use Case 2: visitors who WOULD have been in the prospecting audience, and why they were removed.
with visitors as (
  select distinct rg.genome_id
  from {{ ref('int_source_records') }} r
  join {{ ref('int_record_genome') }} rg on rg.source_record_id = r.source_record_id
  where r.source_system = 'metarouter_page'
    and date(r.event_ts) > date_sub({{ as_of_date() }}, interval {{ var('prospect_lookback_days') }} day)
    and r.session_id in (
      select session_id from {{ ref('int_source_records') }}
      where source_system = 'metarouter_page'
      group by session_id having count(*) > 1
    )
),
reasons as (
  select g.genome_id, s.category as reason
  from {{ ref('customer_genome') }} g
  cross join unnest(g.emails) as email
  join {{ ref('suppression_domains') }} s on s.domain = split(email, '@')[safe_offset(1)]

  union all
  select genome_id, 'recent_booking'
  from {{ ref('customer_genome') }}
  where last_booking_ts is not null
    and date(last_booking_ts) >= date_sub({{ as_of_date() }}, interval {{ var('recent_booker_days') }} day)

  union all
  select genome_id, 'shared_device' from {{ ref('customer_genome') }} where has_shared_identifier

  union all
  select genome_id, 'quarantined' from {{ ref('customer_genome') }} where is_quarantined
)
select
  v.genome_id,
  g.primary_email,
  g.genome_stage,
  string_agg(distinct r.reason order by r.reason) as suppression_reasons
from visitors v
join reasons r on r.genome_id = v.genome_id
join {{ ref('customer_genome') }} g on g.genome_id = v.genome_id
group by v.genome_id, g.primary_email, g.genome_stage
