select
    PatientID as patient_id,
    Age as age,

    Gender as gender_code,
    GenderLabel as gender_label,

    Ethnicity as ethnicity_code,
    EthnicityLabel as ethnicity_label,

    EducationLevel as education_level_code,
    EducationLabel as education_label,

    BMI as bmi,
    Smoking as smoking,
    AlcoholConsumption as alcohol_consumption,
    PhysicalActivity as physical_activity,
    DietQuality as diet_quality,
    SleepQuality as sleep_quality,

    FamilyHistoryAlzheimers as family_history_alzheimers,
    CardiovascularDisease as cardiovascular_disease,
    Diabetes as diabetes,
    Depression as depression,
    HeadInjury as head_injury,
    Hypertension as hypertension,

    SystolicBP as systolic_bp,
    DiastolicBP as diastolic_bp,

    CholesterolTotal as cholesterol_total,
    CholesterolLDL as cholesterol_ldl,
    CholesterolHDL as cholesterol_hdl,
    CholesterolTriglycerides as cholesterol_triglycerides,

    MMSE as mmse,
    MMSEBand as mmse_band,

    FunctionalAssessment as functional_assessment,
    FunctionalAssessmentBand as functional_assessment_band,

    ADL as adl,
    ADLBand as adl_band,

    MemoryComplaints as memory_complaints,
    BehavioralProblems as behavioral_problems,
    Confusion as confusion,
    Disorientation as disorientation,
    PersonalityChanges as personality_changes,
    DifficultyCompletingTasks as difficulty_completing_tasks,
    Forgetfulness as forgetfulness,

    Diagnosis as diagnosis_code,
    DiagnosisLabel as diagnosis_label,

    AgeGroup as age_group,
    MedicalHistoryCount as medical_history_count,
    SymptomCount as symptom_count,

    cast(ProcessingTimestampUTC as timestamptz)
        as processing_timestamp_utc,

    SourceFileName as source_file_name

from "alzheimers_analytics"."main"."silver_alzheimer_patients"