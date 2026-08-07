
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select risk_factor_key
from "alzheimers_analytics"."analytics"."gold_risk_factors"
where risk_factor_key is null



  
  
      
    ) dbt_internal_test