{# Small cleaning helpers used by every staging model. BigQuery SQL. #}

{% macro normalize_email(col) -%}
nullif(lower(trim(cast({{ col }} as string))), '')
{%- endmacro %}

{% macro clean_name(col) -%}
nullif(initcap(trim(cast({{ col }} as string))), '')
{%- endmacro %}

{# Digits only, then US E.164: 10 digits -> +1XXXXXXXXXX, 11 digits starting with 1 -> +1XXXXXXXXXX, else NULL #}
{% macro normalize_phone(col) -%}
(
  case
    when length(regexp_replace(cast({{ col }} as string), r'\D', '')) = 10
      then concat('+1', regexp_replace(cast({{ col }} as string), r'\D', ''))
    when length(regexp_replace(cast({{ col }} as string), r'\D', '')) = 11
         and starts_with(regexp_replace(cast({{ col }} as string), r'\D', ''), '1')
      then concat('+', regexp_replace(cast({{ col }} as string), r'\D', ''))
    else null
  end
)
{%- endmacro %}

{# The "userId" in MetaRouter is the SHA-256 of the lowercase email #}
{% macro email_hash(col) -%}
to_hex(sha256({{ col }}))
{%- endmacro %}

{% macro genome_id(label_col) -%}
concat('cg_', substr(to_hex(md5({{ label_col }})), 1, 12))
{%- endmacro %}

{# Date the whole demo treats as "today" #}
{% macro as_of_date() -%}
date('{{ var("as_of_date") }}')
{%- endmacro %}
