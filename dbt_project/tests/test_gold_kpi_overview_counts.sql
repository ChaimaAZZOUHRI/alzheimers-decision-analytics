select *
from {{ ref('gold_kpi_overview') }}
where total_patients
    <> diagnosed_patients + not_diagnosed_patients
