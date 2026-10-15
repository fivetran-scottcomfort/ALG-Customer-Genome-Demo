-- MetaRouter page events: browsing behaviour. user_id (hashed email) only exists once logged in.
select
  'metarouter_page'                                       as source_system,
  concat('page:', cast(event_id as string))               as source_record_id,
  timestamp(event_ts)                                     as event_ts,
  cast(anonymous_id as string)                            as anonymous_id,
  nullif(trim(cast(user_id as string)), '')               as user_id,
  cast(session_id as string)                              as session_id,
  cast(page_path as string)                               as page_path,
  cast(null as string)                                    as reservation_id,
  cast(null as string)                                    as email,
  cast(null as string)                                    as phone,
  cast(null as string)                                    as first_name,
  cast(null as string)                                    as last_name
from {{ ref('raw_metarouter_page') }}
