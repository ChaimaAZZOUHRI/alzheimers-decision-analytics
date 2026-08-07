select
    patient_id,
    diagnosis_code,

    bmi,
    smoking,
    alcohol_consumption,
    physical_activity,
    diet_quality,
    sleep_quality,

    family_history_alzheimers,
    cardiovascular_disease,
    diabetes,
    depression,
    head_injury,
    hypertension,

    systolic_bp,
    diastolic_bp,

    cholesterol_total,
    cholesterol_ldl,
    cholesterol_hdl,
    cholesterol_triglycerides,

    mmse,
    mmse_band,
    functional_assessment,
    functional_assessment_band,
    adl,
    adl_band,

    memory_complaints,
    behavioral_problems,
    confusion,
    disorientation,
    personality_changes,
    difficulty_completing_tasks,
    forgetfulness,

    medical_history_count,
    symptom_count,

    processing_timestamp_utc,
    source_file_name

from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"