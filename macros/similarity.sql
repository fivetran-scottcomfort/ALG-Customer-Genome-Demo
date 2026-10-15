{#
  text_similarity(a, b): 0 to 1 score. 1 = identical.
  Built from BigQuery's native EDIT_DISTANCE (Levenshtein): 1 - edits / longest_length.
  allow_prefix=true treats nicknames/short forms as a near-match (Jon ~ Jonathan = 0.9).
  Returns NULL if either side is missing, so "no name" never counts as a match or a mismatch.
#}
{% macro text_similarity(a, b, allow_prefix=false) -%}
(
  case
    when {{ a }} is null or {{ b }} is null then null
    when {{ a }} = {{ b }} then 1.0
    {% if allow_prefix -%}
    when least(length({{ a }}), length({{ b }})) >= 3
         and (starts_with({{ a }}, {{ b }}) or starts_with({{ b }}, {{ a }})) then 0.9
    {% endif -%}
    else 1 - safe_divide(edit_distance({{ a }}, {{ b }}), greatest(length({{ a }}), length({{ b }})))
  end
)
{%- endmacro %}
