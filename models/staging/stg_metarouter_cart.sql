-- MetaRouter cart events: someone has a trip in their cart. Carries the device, and the hashed
-- user_id when logged in, so cart activity attaches to the right Customer Genome profile.
-- The trip details (route, dates, hotel) stay in raw_metarouter_cart and are joined in aud_cart_abandon.
select
  'metarouter_cart'                                       as source_system,
  concat('cart:', cast(event_id as string))               as source_record_id,
  timestamp(event_ts)                                     as event_ts,
  cast(anonymous_id as string)                            as anonymous_id,
  nullif(trim(cast(user_id as string)), '')               as user_id,
  cast(session_id as string)                              as session_id,
  '/cart'                                                 as page_path,
  cast(null as string)                                    as reservation_id,
  cast(null as string)                                    as email,
  cast(null as string)                                    as phone,
  cast(null as string)                                    as first_name,
  cast(null as string)                                    as last_name
from {{ ref('raw_metarouter_cart') }}
