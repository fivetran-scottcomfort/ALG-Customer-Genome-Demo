-- AUDIENCE GROWTH: daily new profiles, newly identified profiles, running totals, and fuzzy merges.
with g as (
  select genome_id, date(first_seen_ts) as first_seen_date, date(identified_ts) as identified_date
  from {{ ref('customer_genome') }}
),
spine as (
  select report_date
  from (select min(first_seen_date) as start_date from g),
  unnest(generate_date_array(start_date, {{ as_of_date() }})) as report_date
),
new_by_day as (
  select first_seen_date as report_date, count(*) as new_genomes from g group by 1
),
identified_by_day as (
  select identified_date as report_date, count(*) as newly_identified from g where identified_date is not null group by 1
),
fuzzy_by_day as (
  select date(event_ts) as report_date, count(*) as fuzzy_merges
  from {{ ref('customer_genome_audit_log') }}
  where action = 'merge' and edge_type = 'fuzzy'
  group by 1
),
daily as (
  select
    s.report_date,
    coalesce(n.new_genomes, 0) as new_genomes,
    coalesce(i.newly_identified, 0) as newly_identified,
    coalesce(f.fuzzy_merges, 0) as fuzzy_merges
  from spine s
  left join new_by_day n using (report_date)
  left join identified_by_day i using (report_date)
  left join fuzzy_by_day f using (report_date)
)
select
  report_date,
  new_genomes,
  newly_identified,
  fuzzy_merges,
  sum(new_genomes) over (order by report_date) as total_genomes,
  sum(newly_identified) over (order by report_date) as total_known,
  safe_divide(sum(newly_identified) over (order by report_date),
              sum(new_genomes) over (order by report_date)) as known_rate
from daily
order by report_date
