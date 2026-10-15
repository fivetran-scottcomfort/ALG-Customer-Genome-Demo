-- SUPERNODE GUARD, part 1: shared identifiers.
-- A phone number or device (anonymous_id) tied to more than N different emails is a family line,
-- an agency, or a shared computer. We never use it to merge people.
select
  i.node_id,
  i.identifier_type,
  count(distinct r.email) as distinct_email_count
from {{ ref('int_identifiers') }} i
join {{ ref('int_source_records') }} r
  on r.source_record_id = i.source_record_id
where r.email is not null
  and i.identifier_type in ('phone', 'anonymous_id')
group by 1, 2
having count(distinct r.email) > {{ var('max_emails_per_identifier') }}
