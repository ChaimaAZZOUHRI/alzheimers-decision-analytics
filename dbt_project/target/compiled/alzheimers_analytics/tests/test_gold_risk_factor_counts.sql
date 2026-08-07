select *
from "alzheimers_analytics"."analytics"."gold_risk_factors"
where total_patients
    <> patients_with_factor + patients_without_factor