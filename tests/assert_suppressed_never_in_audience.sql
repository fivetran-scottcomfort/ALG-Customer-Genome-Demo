-- Fails if anyone on the suppression list leaked into the prospecting audience.
select a.genome_id
from {{ ref('aud_prospecting') }} a
join {{ ref('aud_prospecting_suppression_log') }} s on s.genome_id = a.genome_id
