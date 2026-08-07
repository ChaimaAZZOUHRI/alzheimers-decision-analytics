
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select diagnosis_rate_with_factor_pct
from "alzheimers_analytics"."analytics"."gold_risk_factors"
where diagnosis_rate_with_factor_pct is null



  
  
      
    ) dbt_internal_test