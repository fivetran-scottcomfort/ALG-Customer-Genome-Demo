-- Two identifiers that showed up in the SAME record are linked (e.g. an identify event
-- links anonymous_id + email + phone). Flag pairs that touch a shared identifier.
select
  a.node_id as node_a,
  b.node_id as node_b,
  a.identifier_type as type_a,
  b.identifier_type as type_b,
  a.source_record_id,
  a.source_system,
  a.event_ts,
  sa.node_id is not null as a_is_shared,
  sb.node_id is not null as b_is_shared
from {{ ref('int_identifiers') }} a
join {{ ref('int_identifiers') }} b
  on a.source_record_id = b.source_record_id
 and a.node_id < b.node_id
left join {{ ref('int_shared_identifiers') }} sa on sa.node_id = a.node_id
left join {{ ref('int_shared_identifiers') }} sb on sb.node_id = b.node_id
