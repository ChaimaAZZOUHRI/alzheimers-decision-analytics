select *
from "alzheimers_analytics"."analytics"."gold_kpi_overview"
where total_patients
    <> diagnosed_patients + not_diagnosed_patients