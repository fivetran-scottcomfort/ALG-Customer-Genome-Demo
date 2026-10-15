-- IDENTITY GRAPH: connected components via label propagation.
-- Every node starts with its own name as its label. Each pass, a node adopts the smallest label
-- among itself and its neighbours. After enough passes everything linked shares one label.
-- That label (hashed) is the genome_id. graph_iterations must exceed the longest identifier chain;
-- tests/assert_graph_converged.sql fails loudly if it doesn't.
{% set passes = var('graph_iterations') %}
with nodes as (
  select node_id from {{ ref('int_nodes') }}
),
edges as (
  select node_a as src, node_b as dst from {{ ref('int_identity_edges') }}
  union all
  select node_b as src, node_a as dst from {{ ref('int_identity_edges') }}
),
pass_0 as (
  select node_id, node_id as label from nodes
)
{% for i in range(1, passes + 1) %}
, pass_{{ i }} as (
  select
    p.node_id,
    least(p.label, coalesce(min(q.label), p.label)) as label
  from pass_{{ i - 1 }} p
  left join edges e on e.src = p.node_id
  left join pass_{{ i - 1 }} q on q.node_id = e.dst
  group by p.node_id, p.label
)
{% endfor %}
select
  node_id,
  label as component_label,
  {{ genome_id('label') }} as genome_id
from pass_{{ passes }}
