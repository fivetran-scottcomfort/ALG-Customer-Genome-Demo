-- Unpivot: one row per (record, identifier). Each identifier becomes a "node" in the graph.
select
  r.source_record_id,
  r.source_system,
  r.event_ts,
  i.identifier_type,
  i.identifier_value,
  concat(i.identifier_type, ':', i.identifier_value) as node_id
from {{ ref('int_source_records') }} r
cross join unnest([
  struct('anonymous_id'   as identifier_type, r.anonymous_id   as identifier_value),
  struct('email'          as identifier_type, r.email          as identifier_value),
  struct('phone'          as identifier_type, r.phone          as identifier_value),
  struct('reservation_id' as identifier_type, r.reservation_id as identifier_value),
  struct('user_id'        as identifier_type, r.user_id        as identifier_value)
]) as i
where i.identifier_value is not null
