-- FUZZY MATCHING.
-- 1) BLOCKING: only compare emails that share a cheap key, so we never cross-join everyone.
--      block A: SOUNDEX(last name) + first letter of first name
--      block B: identical text before the @ (catches typo'd domains)
-- 2) SCORING: edit-distance similarity on name and on the email's local part.
-- 3) RULES (never merge on a name alone):
--      email_domain_typo      same local part, domain 1-2 edits apart          -> HIGH, auto-merge
--      name_and_email_variant similar name + similar local part + same domain  -> HIGH, auto-merge
--      name_only              similar name, nothing else corroborates          -> MEDIUM, review queue
with entities as (
  select
    *,
    case when first_key is not null and last_key is not null
         then concat(soundex(last_key), '|', substr(first_key, 1, 1)) end as name_block
  from {{ ref('int_email_entities') }}
),

blocked as (
  select a.email as email_a, b.email as email_b
  from entities a join entities b on a.name_block = b.name_block and a.email < b.email
  union distinct
  select a.email as email_a, b.email as email_b
  from entities a join entities b on a.email_local = b.email_local and a.email < b.email
),

scored as (
  select
    bl.email_a,
    bl.email_b,
    ea.email_local = eb.email_local as same_local,
    ea.email_domain = eb.email_domain as same_domain,
    edit_distance(ea.email_domain, eb.email_domain) as domain_edit_distance,
    {{ text_similarity('ea.email_local', 'eb.email_local') }} as email_local_score,
    least(
      {{ text_similarity('ea.first_key', 'eb.first_key', allow_prefix=true) }},
      {{ text_similarity('ea.last_key', 'eb.last_key') }}
    ) as name_score,
    greatest(ea.first_seen_ts, eb.first_seen_ts) as pair_ts
  from blocked bl
  join entities ea on ea.email = bl.email_a
  join entities eb on eb.email = bl.email_b
),

classified as (
  select
    *,
    case
      when same_local and domain_edit_distance between 1 and 2
           and (name_score is null or name_score >= {{ var('fuzzy_name_threshold') }})
        then 'email_domain_typo'
      when name_score >= {{ var('fuzzy_name_threshold') }}
           and email_local_score >= {{ var('fuzzy_email_local_threshold') }}
           and same_domain
        then 'name_and_email_variant'
      when name_score >= {{ var('review_name_threshold') }}
        then 'name_only'
    end as rule
  from scored
)

select
  email_a,
  email_b,
  rule,
  case when rule in ('email_domain_typo', 'name_and_email_variant') then 'high' else 'medium' end as confidence,
  case when rule in ('email_domain_typo', 'name_and_email_variant') then 'auto_merge' else 'queued_for_review' end as decision,
  round((coalesce(name_score, email_local_score) + email_local_score) / 2, 3) as match_score,
  round(name_score, 3) as name_score,
  round(email_local_score, 3) as email_local_score,
  domain_edit_distance,
  pair_ts
from classified
where rule is not null
