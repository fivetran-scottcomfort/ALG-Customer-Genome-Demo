-- The EDGES of the identity graph = every link we trust enough to merge on.
--   deterministic: two identifiers seen together in one record (shared identifiers excluded)
--   fuzzy:         two emails the fuzzy matcher auto-merged (high confidence only)
select
  node_a,
  node_b,
  'deterministic' as edge_type,
  concat(type_a, '+', type_b) as rule,
  'deterministic' as confidence,
  1.0 as match_score,
  min(event_ts) as first_seen_ts,
  array_agg(source_system order by event_ts limit 1)[offset(0)] as evidence_source,
  array_agg(source_record_id order by event_ts limit 1)[offset(0)] as evidence_record
from {{ ref('int_record_pairs') }}
where not a_is_shared and not b_is_shared
group by node_a, node_b, type_a, type_b

union all

select
  concat('email:', email_a) as node_a,
  concat('email:', email_b) as node_b,
  'fuzzy' as edge_type,
  rule,
  confidence,
  match_score,
  pair_ts as first_seen_ts,
  'fuzzy_matcher' as evidence_source,
  concat(email_a, ' ~ ', email_b) as evidence_record
from {{ ref('int_candidate_pairs') }}
where decision = 'auto_merge'
