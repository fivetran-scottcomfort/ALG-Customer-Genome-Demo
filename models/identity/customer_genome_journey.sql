-- Event-by-event stage for each genome: anonymous first visit -> anonymous return -> identified -> known return.
-- Filter to one genome_id (e.g. Maria's) to tell the Use Case 3 story.
with events as (
  select
    rg.genome_id,
    r.source_record_id,
    r.source_system,
    r.event_ts,
    r.session_id,
    r.page_path,
    r.anonymous_id,
    r.email,
    r.user_id,
    if(r.session_id is not null
       and row_number() over (partition by rg.genome_id, r.session_id order by r.event_ts, r.source_record_id) = 1,
       1, 0) as is_new_session,
    if(r.user_id is not null, 1, 0) as is_identifying_event
  from {{ ref('int_source_records') }} r
  join {{ ref('int_record_genome') }} rg on rg.source_record_id = r.source_record_id
),
running as (
  select
    *,
    sum(is_new_session) over w as sessions_so_far,
    max(is_identifying_event) over w as identified_so_far
  from events
  window w as (partition by genome_id order by event_ts, source_record_id
               rows between unbounded preceding and current row)
)
select
  genome_id,
  event_ts,
  source_system,
  page_path,
  anonymous_id,
  email,
  sessions_so_far,
  case
    when identified_so_far = 1 and sessions_so_far >= 2 then 'known_returning'
    when identified_so_far = 1 then 'identified'
    when sessions_so_far >= 2 then 'anonymous_returning'
    else 'anonymous_new'
  end as stage_at_this_event,
  source_record_id
from running
