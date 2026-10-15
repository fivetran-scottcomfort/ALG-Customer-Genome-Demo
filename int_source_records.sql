-- Every event/record from every source, one shape. Step 1 of the Customer Genome.
-- If a record has an email, we also derive its hashed user_id so a logged-in page view
-- (which only carries the hash) can be tied back to the email.
with unioned as (
  select * from {{ ref('stg_metarouter_identify') }}
  union all select * from {{ ref('stg_metarouter_page') }}
  union all select * from {{ ref('stg_metarouter_track') }}
  union all select * from {{ ref('stg_attentive_capture') }}
  union all select * from {{ ref('stg_web_bookings') }}
  union all select * from {{ ref('stg_bq_user_profile') }}
)
select
  source_system,
  source_record_id,
  event_ts,
  anonymous_id,
  coalesce(user_id, case when email is not null then {{ email_hash('email') }} end) as user_id,
  session_id,
  page_path,
  reservation_id,
  email,
  split(email, '@')[safe_offset(1)] as email_domain,
  phone,
  first_name,
  last_name
from unioned
