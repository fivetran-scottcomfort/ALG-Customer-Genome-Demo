-- Fails (returns rows) if one more label-propagation pass would still change any node,
-- meaning graph_iterations is too low for the data. Raise it in dbt_project.yml.
with edges as (
  select node_a as src, node_b as dst from {{ ref('int_identity_edges') }}
  union all
  select node_b, node_a from {{ ref('int_identity_edges') }}
)
select p.node_id
from {{ ref('int_identity_graph') }} p
join edges e on e.src = p.node_id
join {{ ref('int_identity_graph') }} q on q.node_id = e.dst
where q.component_label < p.component_label
