
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select symptom_key
from "alzheimers_analytics"."analytics"."gold_symptoms"
where symptom_key is null



  
  
      
    ) dbt_internal_test