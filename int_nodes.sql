select distinct node_id, identifier_type, identifier_value
from {{ ref('int_identifiers') }}
