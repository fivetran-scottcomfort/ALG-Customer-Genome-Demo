-- Existing BigQuery user profile table.
select
  'bq_user_profile'                                       as source_system,
  concat('bq_profile:', cast(user_id as string))          as source_record_id,
  timestamp(updated_at)                                   as event_ts,
  cast(null as string)                                    as anonymous_id,
  nullif(trim(cast(user_id as string)), '')               as user_id,
  cast(null as string)                                    as session_id,
  cast(null as string)                                    as page_path,
  cast(null as string)                                    as reservation_id,
  {{ normalize_email('email') }}                          as email,
  {{ normalize_phone('phone') }}                          as phone,
  {{ clean_name('first_name') }}                          as first_name,
  {{ clean_name('last_name') }}                           as last_name
from {{ ref('raw_bq_user_profile') }}
