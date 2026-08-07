select *
from {{ ref('gold_symptoms') }}
where total_patients
    <> patients_with_symptom + patients_without_symptom
