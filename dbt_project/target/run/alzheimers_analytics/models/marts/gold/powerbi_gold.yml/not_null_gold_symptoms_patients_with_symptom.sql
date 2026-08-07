
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patients_with_symptom
from "alzheimers_analytics"."analytics"."gold_symptoms"
where patients_with_symptom is null



  
  
      
    ) dbt_internal_test