-- MetaRouter track events (ecommerce purchase): ties a device to a reservation.
select
  'metarouter_track'                                      as source_system,
  concat('track:', cast(event_id as string))              as source_record_id,
  timestamp(event_ts)                                     as event_ts,
  cast(anonymous_id as string)                            as anonymous_id,
  cast(null as string)                                    as user_id,
  cast(null as string)                                    as session_id,
  cast(null as string)                                    as page_path,
  nullif(trim(cast(reservation_id as string)), '')        as reservation_id,
  cast(null as string)                                    as email,
  cast(null as string)                                    as phone,
  cast(null as string)                                    as first_name,
  cast(null as string)                                    as last_name
from {{ ref('raw_metarouter_track') }}
