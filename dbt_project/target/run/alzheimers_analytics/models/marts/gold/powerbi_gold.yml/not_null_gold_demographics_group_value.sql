
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select group_value
from "alzheimers_analytics"."analytics"."gold_demographics"
where group_value is null



  
  
      
    ) dbt_internal_test