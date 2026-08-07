select distinct
    diagnosis_code,
    diagnosis_label

from {{ ref('stg_alzheimer_patients') }}
