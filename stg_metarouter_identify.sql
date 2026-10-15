-- MetaRouter identify events: the moment an anonymous visitor tells us who they are.
select
  'metarouter_identify'                                   as source_system,
  concat('identify:', cast(event_id as string))           as source_record_id,
  timestamp(event_ts)                                     as event_ts,
  cast(anonymous_id as string)                            as anonymous_id,
  cast(null as string)                                    as user_id,
  cast(null as string)                                    as session_id,
  cast(null as string)                                    as page_path,
  cast(null as string)                                    as reservation_id,
  {{ normalize_email('email') }}                          as email,
  {{ normalize_phone('phone') }}                          as phone,
  {{ clean_name('first_name') }}                          as first_name,
  {{ clean_name('last_name') }}                           as last_name
from {{ ref('raw_metarouter_identify') }}
