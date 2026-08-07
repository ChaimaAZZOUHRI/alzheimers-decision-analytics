
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select group_type
from "alzheimers_analytics"."analytics"."gold_demographics"
where group_type is null



  
  
      
    ) dbt_internal_test