select
    patient_id,
    age,
    age_group,
    gender_code,
    gender_label,
    ethnicity_code,
    ethnicity_label,
    education_level_code,
    education_label

from {{ ref('stg_alzheimer_patients') }}
