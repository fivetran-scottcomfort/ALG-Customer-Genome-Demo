-- Attentive email / SMS sign-ups: email + phone, no name.
select
  'attentive_capture'                                     as source_system,
  concat('attentive:', cast(event_id as string))          as source_record_id,
  timestamp(event_ts)                                     as event_ts,
  cast(null as string)                                    as anonymous_id,
  cast(null as string)                                    as user_id,
  cast(null as string)                                    as session_id,
  cast(null as string)                                    as page_path,
  cast(null as string)                                    as reservation_id,
  {{ normalize_email('email') }}                          as email,
  {{ normalize_phone('phone') }}                          as phone,
  cast(null as string)                                    as first_name,
  cast(null as string)                                    as last_name
from {{ ref('raw_attentive_capture') }}
