
  
    
    

    create  table
      "alzheimers_analytics"."analytics"."dim_diagnosis__dbt_tmp"
  
    as (
      select distinct
    diagnosis_code,
    diagnosis_label

from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"
    );
  
  