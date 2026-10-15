-- Which genome does each source record belong to? Use its strongest identifier.
with ranked as (
  select
    i.source_record_id,
    g.genome_id,
    row_number() over (
      partition by i.source_record_id
      order by case i.identifier_type
                 when 'email' then 1 when 'user_id' then 2 when 'reservation_id' then 3
                 when 'anonymous_id' then 4 else 5 end,
               i.node_id
    ) as rn
  from {{ ref('int_identifiers') }} i
  join {{ ref('int_identity_graph') }} g on g.node_id = i.node_id
)
select source_record_id, genome_id from ranked where rn = 1
