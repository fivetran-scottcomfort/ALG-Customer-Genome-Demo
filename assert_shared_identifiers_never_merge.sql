-- Fails if a shared phone/device was ever used as a merge edge.
select e.node_a, e.node_b
from {{ ref('int_identity_edges') }} e
join {{ ref('int_shared_identifiers') }} s on s.node_id in (e.node_a, e.node_b)
