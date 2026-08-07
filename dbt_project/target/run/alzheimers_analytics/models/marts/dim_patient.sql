
  
    
    

    create  table
      "alzheimers_analytics"."analytics"."dim_patient__dbt_tmp"
  
    as (
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

from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"
    );
  
  