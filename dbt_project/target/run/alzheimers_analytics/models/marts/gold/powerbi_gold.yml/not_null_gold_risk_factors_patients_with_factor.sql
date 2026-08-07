
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patients_with_factor
from "alzheimers_analytics"."analytics"."gold_risk_factors"
where patients_with_factor is null



  
  
      
    ) dbt_internal_test