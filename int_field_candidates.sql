-- SURVIVORSHIP, step 1: every value ever seen for a profile field, tagged with where it came from.
-- Step 2 (ranking by the rules in seeds/survivorship_rules.csv) happens in customer_genome.
with records as (
  select rg.genome_id, r.source_system, r.event_ts, r.email, r.phone, r.first_name, r.last_name
  from {{ ref('int_source_records') }} r
  join {{ ref('int_record_genome') }} rg on rg.source_record_id = r.source_record_id
),
unpivoted as (
  select r.genome_id, f.field_name, f.field_value, r.source_system, r.event_ts
  from records r
  cross join unnest([
    struct('email'      as field_name, r.email      as field_value),
    struct('phone'      as field_name, r.phone      as field_value),
    struct('first_name' as field_name, r.first_name as field_value),
    struct('last_name'  as field_name, r.last_name  as field_value)
  ]) as f
  where f.field_value is not null
)
select
  u.genome_id,
  u.field_name,
  u.field_value,
  u.source_system,
  u.event_ts,
  row_number() over (
    partition by u.genome_id, u.field_name
    order by
      case
        when s.strategy = 'source_priority' then
          case when strpos(concat('|', s.source_priority, '|'), concat('|', u.source_system, '|')) = 0
               then 999
               else strpos(concat('|', s.source_priority, '|'), concat('|', u.source_system, '|'))
          end
        else 0
      end,
      u.event_ts desc,
      u.field_value
  ) as survivor_rank
from unpivoted u
left join {{ ref('survivorship_rules') }} s on s.field_name = u.field_name
