
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  select *
from "alzheimers_analytics"."analytics"."gold_symptoms"
where total_patients
    <> patients_with_symptom + patients_without_symptom
  
  
      
    ) dbt_internal_test