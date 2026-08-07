
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_patients
from "alzheimers_analytics"."analytics"."gold_risk_factors"
where total_patients is null



  
  
      
    ) dbt_internal_test