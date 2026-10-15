-- AUDIT TRAIL: every decision the Customer Genome made, and why.
--   merge             two identifiers joined into one profile (deterministic or fuzzy)
--   blocked           a link we refused because the phone/device is shared by different people
--   queued_for_review a fuzzy match that was not strong enough to merge automatically
--   quarantined       a profile that grew too large and was flagged
with merges as (
  select
    e.first_seen_ts as event_ts,
    'merge' as action,
    e.edge_type,
    e.rule,
    e.confidence,
    e.match_score,
    e.node_a,
    e.node_b,
    ga.genome_id as genome_id_a,
    gb.genome_id as genome_id_b,
    concat(e.evidence_source, ' | ', e.evidence_record) as detail
  from {{ ref('int_identity_edges') }} e
  join {{ ref('int_identity_graph') }} ga on ga.node_id = e.node_a
  join {{ ref('int_identity_graph') }} gb on gb.node_id = e.node_b
),

blocked as (
  select
    min(p.event_ts) as event_ts,
    'blocked' as action,
    'deterministic' as edge_type,
    'shared_identifier' as rule,
    'n/a' as confidence,
    cast(null as float64) as match_score,
    p.node_a,
    p.node_b,
    ga.genome_id as genome_id_a,
    gb.genome_id as genome_id_b,
    concat('shared: ', if(p.a_is_shared, p.node_a, p.node_b), ' is tied to multiple emails') as detail
  from {{ ref('int_record_pairs') }} p
  join {{ ref('int_identity_graph') }} ga on ga.node_id = p.node_a
  join {{ ref('int_identity_graph') }} gb on gb.node_id = p.node_b
  where p.a_is_shared or p.b_is_shared
  group by p.node_a, p.node_b, ga.genome_id, gb.genome_id, p.a_is_shared
),

review as (
  select
    c.pair_ts as event_ts,
    'queued_for_review' as action,
    'fuzzy' as edge_type,
    c.rule,
    c.confidence,
    c.match_score,
    concat('email:', c.email_a) as node_a,
    concat('email:', c.email_b) as node_b,
    ga.genome_id as genome_id_a,
    gb.genome_id as genome_id_b,
    concat('name_score=', cast(c.name_score as string), ' email_local_score=', cast(c.email_local_score as string)) as detail
  from {{ ref('int_candidate_pairs') }} c
  join {{ ref('int_identity_graph') }} ga on ga.node_id = concat('email:', c.email_a)
  join {{ ref('int_identity_graph') }} gb on gb.node_id = concat('email:', c.email_b)
  where c.decision = 'queued_for_review'
),

quarantined as (
  select
    timestamp('{{ var("as_of_date") }}') as event_ts,
    'quarantined' as action,
    'component' as edge_type,
    'max_component_size' as rule,
    'n/a' as confidence,
    cast(null as float64) as match_score,
    cast(null as string) as node_a,
    cast(null as string) as node_b,
    genome_id as genome_id_a,
    genome_id as genome_id_b,
    concat('profile has ', cast(node_count as string), ' identifiers (limit {{ var("max_component_size") }})') as detail
  from {{ ref('int_genome_components') }}
  where is_quarantined
),

unioned as (
  select * from merges
  union all select * from blocked
  union all select * from review
  union all select * from quarantined
)

select
  to_hex(md5(concat(action, '|', coalesce(node_a, ''), '|', coalesce(node_b, ''), '|', rule, '|', coalesce(genome_id_a, '')))) as audit_id,
  *
from unioned
