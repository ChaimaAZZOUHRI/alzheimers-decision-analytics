select *
from "alzheimers_analytics"."analytics"."gold_symptoms"
where total_patients
    <> patients_with_symptom + patients_without_symptom