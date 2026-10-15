-- One row per email with its best-known name. Fuzzy matching compares these.
select
  email,
  split(email, '@')[safe_offset(0)] as email_local,
  split(email, '@')[safe_offset(1)] as email_domain,
  array_agg(lower(first_name) ignore nulls order by event_ts desc limit 1)[safe_offset(0)] as first_key,
  array_agg(lower(last_name)  ignore nulls order by event_ts desc limit 1)[safe_offset(0)] as last_key,
  min(event_ts) as first_seen_ts
from {{ ref('int_source_records') }}
where email is not null
group by email
