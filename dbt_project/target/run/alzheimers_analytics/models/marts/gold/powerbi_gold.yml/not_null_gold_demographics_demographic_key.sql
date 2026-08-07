
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select demographic_key
from "alzheimers_analytics"."analytics"."gold_demographics"
where demographic_key is null



  
  
      
    ) dbt_internal_test