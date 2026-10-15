-- Web booking events (ecommerce purchase): email + reservation + name.
select
  'web_booking'                                           as source_system,
  concat('booking:', cast(reservation_id as string))      as source_record_id,
  timestamp(booking_ts)                                   as event_ts,
  cast(null as string)                                    as anonymous_id,
  cast(null as string)                                    as user_id,
  cast(null as string)                                    as session_id,
  cast(null as string)                                    as page_path,
  nullif(trim(cast(reservation_id as string)), '')        as reservation_id,
  {{ normalize_email('email') }}                          as email,
  {{ normalize_phone('phone') }}                          as phone,
  {{ clean_name('first_name') }}                          as first_name,
  {{ clean_name('last_name') }}                           as last_name
from {{ ref('raw_web_bookings') }}
