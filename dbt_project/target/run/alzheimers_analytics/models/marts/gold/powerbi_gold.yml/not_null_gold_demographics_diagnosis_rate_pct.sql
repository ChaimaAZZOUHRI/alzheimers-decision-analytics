
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select diagnosis_rate_pct
from "alzheimers_analytics"."analytics"."gold_demographics"
where diagnosis_rate_pct is null



  
  
      
    ) dbt_internal_test