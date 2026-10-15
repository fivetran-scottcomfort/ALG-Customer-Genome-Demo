-- Size and make-up of each genome. SUPERNODE GUARD, part 2: oversized components are quarantined.
select
  g.genome_id,
  count(*) as node_count,
  countif(n.identifier_type = 'email') as email_count,
  countif(n.identifier_type = 'anonymous_id') as anonymous_id_count,
  array_agg(if(n.identifier_type = 'anonymous_id', n.identifier_value, null) ignore nulls) as anonymous_ids,
  array_agg(if(n.identifier_type = 'reservation_id', n.identifier_value, null) ignore nulls) as reservation_ids,
  count(*) > {{ var('max_component_size') }} as is_quarantined,
  logical_or(s.node_id is not null) as has_shared_identifier
from {{ ref('int_identity_graph') }} g
join {{ ref('int_nodes') }} n on n.node_id = g.node_id
left join {{ ref('int_shared_identifiers') }} s on s.node_id = g.node_id
group by g.genome_id
